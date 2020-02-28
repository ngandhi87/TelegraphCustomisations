/* Imported from plugin PROC/AssetChecker/16.4.2.0 */
/*
CATEGORY: Maintenance
DESCRIPTION: Used by the Database Model Checker System Management process to check database objects
*/

/**
	CHP Database Model Checker
	
	This script is used by the Database Model Checker System Management process that provides a tool for performing various
	checks on the contents of a CHP database.
	
	In general, the checks performed are run at the database level and bypasses the API - this is so that the "low-level" consistency can be checked.
	(for example, if a folder gets orphaned, then the API would never find that entry as it's not linked into the hierarchy any more, however this checker will still find and report on it).

 */
import com.picdar.mogulsupport.Segments.SegmentUtils
import com.picdar.process2.Core.*;

import com.picdar.MediaMogulSite.MISLogging.MISWebLogger;

import com.picdar.common.DataSource.*;
import com.picdar.common.DataSource.FieldInformation.*;
import com.picdar.common.Http.Http;
import com.picdar.common.KeyValue.KeyValue;
import com.picdar.common.Lucene.*;
import com.picdar.common.MIME.*;
import com.picdar.common.ObjectPool.ObjectPool;
import com.picdar.common.Utilities.*;
import com.picdar.common.XMLSupport.Utils.XMLUtils;

import com.picdar.eis.JDBC.PrimaryKey.PrimaryKeyManager;
import com.picdar.eis.DataSourceManager.DataSourceManager;
import com.picdar.eis.JDBC.ConnectionPool.JDBCPooledConnection;
import com.picdar.eis.JDBC.VendorSpecific.VendorSpecificJDBC;
import com.picdar.eis.Solr.ConnectionPool.*;
import com.picdar.eis.JAMI.*;

import com.picdar.mogulsupport.Pool.DatabaseUtils;
import com.picdar.mogulsupport.Security.UserModel;

import com.picdar.process.Core.ProcessModule;

import com.picdar.resource.AppPrefsManager.*;
import com.picdar.resource.AssetAccess.*;
import com.picdar.resource.Core.*;
import com.picdar.resource.ConfigManager.*;
import com.picdar.resource.CollectionManager.CollectionManager;
import com.picdar.resource.DataManager.DataManager;
import com.picdar.resource.FolderFavouriteManger.*;
import com.picdar.resource.HierarchicalDB.*;
import com.picdar.resource.I18nManager.I18nUtils;
import com.picdar.resource.I18nManager.MessageTranslator.MessageTranslator;
import com.picdar.resource.MISManager.*;
import com.picdar.resource.PoolManager.PoolManager;
import com.picdar.resource.QueueManager.*
import com.picdar.resource.ScriptManager.ScriptManager;
import com.picdar.resource.SearchManager.*;
import com.picdar.resource.SearchManager.SOLR.QueryGeneration.*;
import com.picdar.resource.SearchManager.Support.TopTerms.*;
import com.picdar.resource.SecurityAccessManager.*;
import com.picdar.resource.TransactionManager.*;
import com.picdar.resource.WorkflowManager.*;
import com.picdar.resource.UserManager.*;
import com.picdar.resource.XMLManager.*;

import com.picdar.AdminSite.PROC.ProcessUtils;

import com.picdar.webapplication.ApplicationManagement.*;
import com.picdar.webapplication.Core.*;
import com.picdar.webapplication.Core.Events.*
import com.picdar.webapplication.Server.ValidationFilter.AntiSamyValidationRule

import javax.annotation.Resource
import javax.swing.text.Segment;
import java.sql.*;
import java.util.*;
import org.w3c.dom.*;
import org.json.*;
import org.apache.lucene.search.*;
import org.owasp.esapi.ESAPI;

import org.owasp.validator.html.AntiSamy;
import org.owasp.validator.html.CleanResults;
import org.owasp.validator.html.ScanException;

import java.util.regex.Pattern;

public class DatabaseModelChecker extends com.picdar.process2.Core.ProcessModuleSkeletonScript
	{
	public static final String PARAM_CHECKS = "checks_to_perform";
	public static final String PARAM_ASSET_SQL = "asset_sql";
	public static final String PARAM_ASSET_CHECKS = "asset_checks";
	public static final String PARAM_ASSET_SEARCH = "asset_search";
	public static final String PARAM_ASSET_TYPES_TO_RETRIEVE = "asset_retrieval_types";
	public static final String PARAM_ASSET_SELECTION = "asset_selection";
	public static final String PARAM_QUEUE_NAME = "queue_name";
	public static final String PARAM_CLEAR_QUEUE = "clear_queue_at_start";
    public static final String PARAM_OFFSET_FUTURE_DATE = "offset_future_date";
	
	public static final int ASSET_BATCH_SIZE = 1000;

    public static final int FUTURE_DATE_OFFSET_SECS = 300; // 5 minutes offset for the future creation stamp

	protected List<String> itsUserGroupIDs = null;
	protected List<String> itsUserAccountIDs = null;

	public DatabaseModelChecker()
	  	{
		}

	public DatabaseModelChecker(HashMap props)
		{
    	super(props);
		}

	public String getDescription()
		{
		return "Script for running database model checking";
		}

	public String getName()
		{
		return "DatabaseModelChecker";
		}

	protected void recordProblemFound(String object_id, String description)
		{
		QueueManager qm = ResourceManager.getInstance().getResource(QueueManager.RESOURCE_NAME);
		String queue_name = getConfigValue(PARAM_QUEUE_NAME);
		Queue index_queue = qm.getQueue(queue_name);		
		index_queue.addItem(object_id, "", 0, "Administrator", null, description, null, true);
		}

	/* check the given owner for an object */
	protected void checkObjectOwner(String primary_key, String owner_id, String name, String object_type)
		{
		// check that the owner is either System, or a valid user group or user ID
		if (owner_id.equalsIgnoreCase("System"))
			{
			// then owner ID is OK
			}
		else if (itsUserGroupIDs.contains(owner_id))
			{
			// then owner ID is OK
			}
		else if (itsUserAccountIDs.contains(owner_id))
			{
			// then owner ID is OK
			}
		else
			{
			// we didn't match the owner_id against a valid value, so report it
			logMessage("Failed to match owner " + owner_id + " of " + object_type + " " + name + " " + primary_key + " to any valid user group or user account." , MISManager.PRIORITY_WARNING);
			recordProblemFound(primary_key, "Owner " + owner_id + " is invalid for " + object_type + " (" + name + ")");
			}
		}
	
	/* load and check the policies for an object */
	protected void checkObjectPolicies(String primary_key, String name, String object_type, String opt_owner_id)
		{
		SecurityAccessManager sam = (SecurityAccessManager) ResourceManager.getInstance().getResource(SecurityAccessManager.RESOURCE_NAME);
		
		PrimaryKey pk = new PrimaryKey(primary_key);
		PrimaryKeyManager.normalisePK(pk);
		
		// load the policy table for the object
		PolicyTable policies = null; 
		if (object_type.equals("asset"))
			policies = sam.getPolicies(SecurityAccessManager.PolicyType.ASSET, pk);
		else
			policies = sam.getPolicies(SecurityAccessManager.PolicyType.FOLDER, pk);

		// step over each policy and check that the group/user is valid
		ArrayList<String> policies_seen = new ArrayList<String>();
		for (int i = 0; i < policies.size(); ++i)
			{
                com.picdar.resource.SecurityAccessManager.Policy pol = policies.getPolicy(i);
			String check_id = pol.getRoleId();
			if (check_id == null || check_id.equals(""))
				check_id = pol.getUserId();

			if (check_id != null && !check_id.equals(""))
				{
				logMessage("Checking user/group of " + check_id + " for " + primary_key, MISManager.PRIORITY_DEBUG);

				// check for duplicate policies
				if (policies_seen.contains(check_id))
					{
					logMessage("Found more than one policy for the same user/group against " + object_type + " " + name + " " + primary_key + "." , MISManager.PRIORITY_WARNING);
					recordProblemFound(primary_key, "Duplicate policies");
					}
				else
					{
					policies_seen.add(check_id);

					// check that the owner is either System, or a valid user group or user ID
					if (check_id.equalsIgnoreCase("System"))
						{
						// then owner ID is OK
						}
					else if (itsUserGroupIDs.contains(check_id))
						{
						// then owner ID is OK
						}
					else if (itsUserAccountIDs.contains(check_id))
						{
						// then owner ID is OK
						}
					else
						{
						// we didn't match the check_id against a valid value, so report it
						logMessage("Failed to match policy ID of " + check_id + " for " + object_type + " " + name + " " + primary_key + " to any valid user group or user account." , MISManager.PRIORITY_WARNING);
						recordProblemFound(primary_key, "Invalid policy user/group " + check_id);
						}
					}
				}
			
			// check for policy being same as owner
			if (check_id != null && !check_id.equals("") && opt_owner_id != null && !opt_owner_id.equals("")
				&& check_id == opt_owner_id)
				{
				logMessage(object_type + " " + name + " " + primary_key + " has a policy with the same ID as the owner." , MISManager.PRIORITY_WARNING);
				recordProblemFound(primary_key, "Policy same as owner - " + check_id);				
				}			 
			}		
		}

        /* check the linked_assets associated to the main record */
        protected void checkAssociatedTables(String assetID, String tableName, String fields, String keyField) {
            // the checks are performed directly against the database (don't trust what's in the cache)
            JDBCPooledConnection pooledConn = null;
            Statement statement = null;
            ResultSet rs = null;
            CollectionManager cm = null;
            try {
                pooledConn = DatabaseUtils.getJDBCConnectionForPool("JDBC");
                String expectedSystemID = DataSourceManager.getInstance().getSystemIDForSource("default");
                // assume default data source
                String expectedDBID = DataSourceManager.getInstance().getDatabaseIDForSource("default");
                String expectedPrefix = expectedSystemID + expectedDBID;
                // logMessage("Running checks on LINKED_ASSET.", MISManager.PRIORITY_INFO);

                statement = pooledConn.prepareStatement("SELECT " + fields + " FROM " + tableName + " WHERE ASSET_ID = ?");
                statement.setString(1, assetID);
                // count the folders so we can show progress
                rs = statement.executeQuery();

                while (rs.next()) {

                    String linkedAssetID = rs.getString(2);
                    String linkID = rs.getString(3);
                    // String segmentsXML = rs.getString(4);
                    // Timestamp creationStamp = rs.getTimestamp(5);
                    // Timestamp timeStamp = rs.getTimestamp(6);
                    // String type = rs.getString(7);

                    if (!linkID.substring(0, 8).equals(expectedPrefix)) {
                        logMessage("Link ID key " + linkID + " doesn't have expected system/database ID of " + expectedPrefix, MISManager.PRIORITY_WARNING);
                        recordProblemFound(linkID, "Invalid primary key format");
                    }

                    // check the asset table although it may exist in the main table of the asset like PICTURE etc.
                    if (!does_object_exist("ASSET", "ASSET_ID", linkedAssetID)) {
                        logMessage("Asset key " + linkID + " associated to " + assetID + " doesn't exist", MISManager.PRIORITY_WARNING);
                        recordProblemFound(linkID, "Linked asset doesn't exist");
                    }

                    // Could add more checks here in the future but this is a good start
                }

            } catch (SQLException | ResourceException e)
                {
                    logMessage("Failed to perform linked asset checks:" + e.getMessage() , MISManager.PRIORITY_ERROR);
                }
                finally
                {
                    try
                    {
                        if (rs != null)
                            rs.close();
                        if (statement != null)
                            statement.close();
                        if (pooledConn != null)
                            pooledConn.release();
                    }
                    catch (Exception e)
                    {
                        logMessage("Failed to tidy up after previous error:" + e.getMessage() , MISManager.PRIORITY_ERROR);
                    }
                }
        }

	/* check the parent for a folder */
	protected void checkParent(String primary_key, String parent_id, String tableName, String name, String object_type)
		{
		JDBCPooledConnection pooledConn = null;
		PreparedStatement statement = null;
		ResultSet rs = null;
		try
			{
			pooledConn = DatabaseUtils.getJDBCConnectionForPool("JDBC");
			statement = pooledConn.prepareStatement("SELECT COUNT(1) FROM " + tableName + " WHERE NODE_ID=?");
			statement.setString(1, parent_id);
			// count the folders so we can show progress
			rs = statement.executeQuery();
			rs.next();
			int folderCount = rs.getInt(1);
			rs.close();		
			
			if (folderCount == 0)
				{
				logMessage("Failed to find parent " + parent_id + " for " + object_type + " " + name + " " + primary_key + "." , MISManager.PRIORITY_WARNING);
				recordProblemFound(primary_key, "Parent with ID " + parent_id + " missing");				
				}
			}
		catch (SQLException | ResourceException e)
			{
			logMessage("Failed to perform folder checks on " + tableName + ":" + e.getMessage() , MISManager.PRIORITY_ERROR);
			}
		finally
			{
			try
				{
				if (rs != null)
					rs.close();
				if (statement != null)
					statement.close();
				if (pooledConn != null)
					pooledConn.release();
				}
			catch (Exception e)
				{
				logMessage("Failed to tidy up after previous error:" + e.getMessage() , MISManager.PRIORITY_ERROR);
				}
			}
		}	
	
	/* get the collection manager for the given table */
	protected CollectionManager getCollectionManager(String tableName) throws ResourceException
		{
		CollectionManager cm = null;
		if (tableName.equalsIgnoreCase("HARD_CATEGORIES"))
			cm = (CollectionManager) ResourceManager.getInstance().getResource("CategoryCollectionManager");
		else if (tableName.equalsIgnoreCase("MM_SHELF"))
			cm = (CollectionManager) ResourceManager.getInstance().getResource("ShelfCollectionManager");
		else if (tableName.equalsIgnoreCase("FEEDS"))
			cm = (CollectionManager) ResourceManager.getInstance().getResource("FeedsCollectionManager");
		else if (tableName.equalsIgnoreCase("PACKAGES"))
			cm = (CollectionManager) ResourceManager.getInstance().getResource("PackageCollectionManager");
		else if (tableName.equalsIgnoreCase("MM_PARKING"))
			cm = (CollectionManager) ResourceManager.getInstance().getResource("ParkingCollectionManager");
		return cm;
		}
	
	/* check for existence for a list of asset IDs */
	protected void checkForAssetsExistence(List<String> keys, String msgStart)
		{
		JDBCPooledConnection pooledConn = null;
		Statement statement = null;
		ResultSet rs = null;
		try
			{
			pooledConn = DatabaseUtils.getJDBCConnectionForPool("JDBC");
			statement = pooledConn.createStatement();
			
			String sql = "SELECT ASSET_ID FROM ASSET WHERE ";
			for (int i = 0; i < keys.size(); ++i)
				{
				if (i > 0)
					sql += " OR ";
				sql += "(ASSET_ID='" + keys.get(i) + "')";
				}
			
			rs = statement.executeQuery(sql);
			int folderNum = 0;
			HashMap<String,String> keysFound = new HashMap<String, String>();
			while (rs.next())
				{
				String found_asset = rs.getString(1);
				keysFound.put(found_asset, found_asset);
				}
			
			for (int i = 0; i < keys.size(); ++i)
				{
				String id_to_check = keys.get(i);
				if (keysFound.get(id_to_check) == null)
					{
					logMessage("Failed to find asset with ID " + id_to_check + " (" + msgStart + ")." , MISManager.PRIORITY_WARNING);
					recordProblemFound(id_to_check, "Missing in ASSET table (" + msgStart + ")");				
					}
				}
			}
		catch (SQLException | ResourceException e)
			{
			logMessage("Failed to perform asset existence checks:" + e.getMessage() + "." , MISManager.PRIORITY_ERROR);
			}
		finally
			{
			try
				{
				if (rs != null)
					rs.close();
				if (statement != null)
					statement.close();
				if (pooledConn != null)
					pooledConn.release();
				}
			catch (Exception e)
				{
				logMessage("Failed to tidy up after previous error:" + e.getMessage() , MISManager.PRIORITY_ERROR);
				}
			}
		}
	
	/* perform checks for a folder structure */
	protected void doFolderChecks(String tableName, String linkTableName, String object_type, boolean hasOwner, boolean isFullKey)
		{		
		// the checks are performed directly against the database (don't trust what's in the cache)
		JDBCPooledConnection pooledConn = null;
		Statement statement = null;
		ResultSet rs = null;
		CollectionManager cm = null;
		try
			{
			String expectedSystemID = DataSourceManager.getInstance().getSystemIDForSource("default"); // assume default data source
			String expectedDBID = DataSourceManager.getInstance().getDatabaseIDForSource("default");
			String expectedPrefix = expectedSystemID + expectedDBID;			
			
			setProcessMessage("Running checks on " + object_type + " hierarchy....");
			logMessage("Running checks on " + object_type + " hierarchy." , MISManager.PRIORITY_INFO);
			
			cm = getCollectionManager(tableName);

			pooledConn = DatabaseUtils.getJDBCConnectionForPool("JDBC");
			statement = pooledConn.createStatement();
			
			// count the folders so we can show progress
			rs = statement.executeQuery("SELECT COUNT(1) FROM " + tableName);
			rs.next();
			int folderCount = rs.getInt(1);
			rs.close();
			
			if (hasOwner)
				rs = statement.executeQuery("SELECT NODE_ID,PARENT_ID,KEY,KEY_LEVEL,OWNER_ID FROM " + tableName);
			else
				rs = statement.executeQuery("SELECT NODE_ID,PARENT_ID,KEY,KEY_LEVEL FROM " + tableName);

			int folderNum = 0;
			boolean keepGoing = true;
			HashMap<String,String> allFolderIDs = new HashMap<String, String>();
			while (keepGoing && rs.next())
				{
				if ((folderNum % 50) == 0)
					{
					logMessage("Checked " + folderNum + " " + object_type + " out of " + folderCount, MISManager.PRIORITY_INFO);
					if (handleCurrentCommand() != ProcessModule.CONTINUE)
						keepGoing = false;
					}

				String folder_node_id = rs.getString(1);
				String folder_parent_id = rs.getString(2);
				String folder_name = rs.getString(3);
				String folder_level = rs.getString(4);
				String folder_owner = null;
				if (hasOwner)
					folder_owner = rs.getString(5);
				
				if (!folder_node_id.equals(HierarchicalDB.ROOT_PARENTID))
					{
					String path = "Unknown";
					try
						{
						path = cm.getFullPathForNodeId(null, folder_node_id);
						}
					catch (Exception e)
						{
						path = "Unknown";
						}

					// check primary key matches local system/database ID
					if (isFullKey)
						{
						if (folder_node_id.length() < 8 || !folder_node_id.substring(0, 8).equals(expectedPrefix))
							{
							logMessage("Primary key " + folder_node_id + " doesn't not have expected system/database ID of " + expectedPrefix + " when checking table " + tableName + ".", MISManager.PRIORITY_WARNING);
							recordProblemFound(folder_node_id, "Incorrect primary key format");				
							}
						}

					checkParent(folder_node_id, folder_parent_id, tableName, path, object_type);
					if (folder_owner != null)
						{
						checkObjectOwner(folder_node_id, folder_owner, path, object_type);
						checkObjectPolicies(folder_node_id, path, object_type, null);
						}
					}
	
				allFolderIDs.put(folder_node_id, folder_node_id);
				
				++folderNum;
				}
			rs.close();
			
			// count the links so we can show progress
			if (keepGoing && linkTableName != null)
				{
				rs = statement.executeQuery("SELECT COUNT(1) FROM " + linkTableName);
				rs.next();
				int linkCount = rs.getInt(1);
				rs.close();

				// check links tables - make sure entries at each end are valid items
				rs = statement.executeQuery("SELECT NODE_ID, ASSET_ID FROM " + linkTableName);
				int linkNum = 0;
				ArrayList<String> asset_ids = new ArrayList<String>();
				HashMap<String, ArrayList<String>> assets_by_node = new HashMap<String, ArrayList<String>>();
				while (keepGoing && rs.next())
					{
					if ((linkNum % 1000) == 0)
						{
						logMessage("Checked " + linkNum + " " + linkTableName + " links out of " + linkCount, MISManager.PRIORITY_INFO);
						if (handleCurrentCommand() != ProcessModule.CONTINUE)
							keepGoing = false;
						}

					String link_node_id = rs.getString(1);
					String link_asset_id = rs.getString(2);
				
					if (allFolderIDs.get(link_node_id) == null)
						{
						logMessage("A link in " + linkTableName + " refers to folder ID " + link_node_id + " that doesn't exist in the folder table " + tableName + ".", MISManager.PRIORITY_WARNING);
						recordProblemFound(link_node_id, "Invalid folder " + link_node_id + " in " + linkTableName);
						}
					else
						{
						ArrayList<String> assets_for_node = assets_by_node.get(link_node_id);
						if (assets_for_node == null)
							{
							assets_for_node = new ArrayList<String>();
							assets_by_node.put(link_node_id, assets_for_node);
							}
						assets_for_node.add(link_asset_id);
						}
	
					++linkNum;
					}
			
				// go through each node and check the links for it
				Iterator<String> it = assets_by_node.keySet().iterator();
				int nodes_size = assets_by_node.keySet().size();
				int link_check_count = 0;
				while (keepGoing && it.hasNext())
					{
					String node_id = it.next();
					
					if ((link_check_count % 50) == 0)
						{
						logMessage("Checked for assets existing on links for " + link_check_count + " nodes out of " + nodes_size, MISManager.PRIORITY_INFO);
						if (handleCurrentCommand() != ProcessModule.CONTINUE)
							keepGoing = false;
						}					
					
					ArrayList<String> keys_for_node = assets_by_node.get(node_id);
					ArrayList<String> keys_to_check = new ArrayList<String>();
					// filter out any editions that might have been linked into a folder
					for (String a_key : keys_for_node)
						{
						if (a_key.indexOf("EDIN") == -1)
							keys_to_check.add(a_key);
						}
					if (keys_to_check.size() > 100000)
						logMessage("Skipping checking links for large folder " + node_id + " with " + keys_to_check.size() + " links...", MISManager.PRIORITY_INFO);
					else
						checkForAssetsExistence(keys_to_check, "Checking assets in " + linkTableName + " for node with ID " + node_id);
					
					++link_check_count;
					}				
				}
				
			// for personal folders, perform an additional special check that top-level entries all match user names
			if (tableName.equals("MM_SHELF"))
				{
				rs = statement.executeQuery("SELECT NODE_ID,KEY FROM " + tableName + " WHERE KEY_LEVEL=0");
				folderNum = 0;
				while (keepGoing && rs.next())
					{					
					if ((folderNum % 1000) == 0)
						{
						logMessage("Checked " + folderNum + " personal folders", MISManager.PRIORITY_INFO);
						if (handleCurrentCommand() != ProcessModule.CONTINUE)
							keepGoing = false;
						}
					
					String node_id = rs.getString(1);
					String user_name = rs.getString(2);
					if (!does_object_exist("MM_USER", "NAME", user_name))
						{
						logMessage("Personal folder for " + user_name + " exists when the user cannot be found.", MISManager.PRIORITY_WARNING);
						recordProblemFound(node_id, "Personal folder found for " + user_name + " when the user no longer exists");
						} 
					
					++folderNum;
					}
				}
			}
		catch (SQLException | ResourceException e)
			{
			logMessage("Failed to perform folder checks on " + tableName + ":" + e.getMessage(), MISManager.PRIORITY_ERROR);
			}
		finally
			{
			try
				{
				if (rs != null)
					rs.close();
				if (statement != null)
					statement.close();
				if (pooledConn != null)
					pooledConn.release();
				}
			catch (Exception e)
				{
				logMessage("Failed to tidy up after previous error:" + e.getMessage() , MISManager.PRIORITY_ERROR);
				}
			}
		}
	
	/* load any data values we will use frequently while checking */
	protected void loadCacheLookups()
		{
		itsUserGroupIDs = new ArrayList<String>();
		itsUserAccountIDs = new ArrayList<String>();
		
		JDBCPooledConnection pooledConn = null;
		Statement statement = null;
		ResultSet rs = null;
		try
			{
			pooledConn = DatabaseUtils.getJDBCConnectionForPool("JDBC");
			statement = pooledConn.createStatement();
			
			rs = statement.executeQuery("SELECT ROLE_ID FROM MM_ROLE");
			while (rs.next())
				itsUserGroupIDs.add(rs.getString(1));
			rs.close();
			
			rs = statement.executeQuery("SELECT USER_ID FROM MM_USER");
			while (rs.next())
				itsUserAccountIDs.add(rs.getString(1));
			rs.close();
			}
		catch (SQLException | ResourceException e)
			{
			logMessage("Failed to load cache data:" + e.getMessage(), MISManager.PRIORITY_ERROR);
			}
		finally
			{
			try
				{
				if (rs != null)
					rs.close();
				if (statement != null)
					statement.close();
				if (pooledConn != null)
					pooledConn.release();
				}
			catch (Exception e)
				{
				logMessage("Failed to tidy up after previous error:" + e.getMessage() , MISManager.PRIORITY_ERROR);
				}
			}		
		}
	
	protected String expandKeyList(ArrayList<String> keys)
		{
		String expandedKeys = new String();
		for (String a_key : keys)
			expandedKeys += "'" + a_key + "',";
		return expandedKeys.substring(0, expandedKeys.length() - 1);
		}
	
	/* check a set of keys against the indexes */
	protected int checkIndexStatus(ArrayList<String> keys_for_batch) throws Exception
		{
		int num_problems = 0;

		PoolManager pm = (PoolManager) ResourceManager.getInstance().getResource(PoolManager.RESOURCE_NAME);
		SolrConnectionPool solr_pool = (SolrConnectionPool) pm.getPool("SolrCloud");
		SolrPooledConnection searchPool = (SolrPooledConnection) solr_pool.get("Index sanity checks");
		
		try
			{		
			String searchStr = "";
			for (int i = 0; i < keys_for_batch.size(); ++i)
				{
				String a_key = keys_for_batch.get(i);
				if (i > 0)
					searchStr += " || ";
				searchStr += "doc_id:" + a_key + "\\:0";
				}
	
			SolrPreparedQuery query = new SolrPreparedQuery("assets", null, searchStr, null, "doc_id desc");
			SolrSearchResponse resp = searchPool.search(query, SolrPooledConnection.SOLR_STARTING_CURSOR_MARK, ASSET_BATCH_SIZE);
			List<String> search_keys = resp.getKeys();
			QueueManager qm = ResourceManager.getInstance().getResource("BacklogIndexQueueManager");
			Queue index_queue = qm.getQueue("MM_INDEX_QUEUE");
			
			for (int i = 0; i < keys_for_batch.size(); ++i)
				{
				String a_key = keys_for_batch.get(i);
				if (!search_keys.contains(a_key + ":0"))
					{
					logMessage("Failed to find entry for key " + a_key + " in SOLR index - adding to indexing queue for reprocessing",  MISManager.PRIORITY_WARNING);	
					// add into the indexing queue
					index_queue.addItem(a_key, "index", 0, "Administrator", null);
					++num_problems;
					}
				}
			}
		finally
			{
			searchPool.release();
			}
			
		return num_problems;
		}
		
	/* check a set of keys against the asset store */
	protected int checkAssetFiles(ArrayList<String> keys_for_batch, String types_to_check) throws Exception
		{
		int num_problems = 0;
		
		AssetTypeMask checker_types = new AssetTypeMask(types_to_check);
		
		// load the cookie and locator info for the list of asset keys
		JDBCPooledConnection pooledConn = null;
		Statement statement = null;
		ResultSet rs = null;
		HashMap<String, String> assetCookies = new HashMap<String, String>();
		try
			{
			pooledConn = DatabaseUtils.getJDBCConnectionForPool("JDBC");
			statement = pooledConn.createStatement();
			
			String sql = "SELECT ASSET_ID,COOKIE FROM ASSET_INFO WHERE ";
			for (int i = 0; i < keys_for_batch.size(); ++i)
				{
				if (i > 0)
					sql += " OR ";
				sql += "(ASSET_ID='" + keys_for_batch.get(i) + "')";
				}
				
			rs = statement.executeQuery(sql);
			while (rs.next())
				{
				String asset_id = rs.getString(1);
				String asset_cookie = rs.getString(2);

				assetCookies.put(asset_id, asset_cookie);
				}
			}
		catch (SQLException | ResourceException e)
			{
			logMessage("Failed to load asset cookies:" + e.getMessage() + "." , MISManager.PRIORITY_ERROR);
			}
		finally
			{
			try
				{
				if (rs != null)
					rs.close();
				if (statement != null)
					statement.close();
				if (pooledConn != null)
					pooledConn.release();
				}
			catch (Exception e)
				{
				logMessage("Failed to tidy up after previous error:" + e.getMessage() , MISManager.PRIORITY_ERROR);
				}
			}		
		
		// check for locator entries, and check what items are available
		AssetAccess aa = (AssetAccess) ResourceManager.getInstance().getResource(AssetAccess.RESOURCE_NAME);
		boolean keepGoing = true;
		for (int key_pos = 0; keepGoing && key_pos < keys_for_batch.size(); ++key_pos)
			{
			String a_key = keys_for_batch.get(key_pos);			
			
			if (key_pos != 0 && (key_pos % 100) == 0)
				{
				setProcessMessage("Doing binary file checks on " + keys_for_batch.size() + " items...completed " + key_pos + " so far...");
				if (handleCurrentCommand() != ProcessModule.CONTINUE)
					keepGoing = false;
				}
			
			String cookie_txt = assetCookies.get(a_key);
			if (cookie_txt == null)
				{
				if (a_key.indexOf("STRY") == -1 && a_key.indexOf("EXTN") == -1)
					{
					logMessage("Asset " + a_key + " doesn't have an entry in the ASSET_INFO table", MISManager.PRIORITY_WARNING);
					// don't log this into the queue table...it just indicates the asset doesn't have any binary files attached, which may be OK
					++num_problems;
					}
				}
			else
				{
				AssetCookie a_cookie = new AssetCookie(cookie_txt);
				AssetReference[] refs = aa.getReferences(a_cookie, checker_types);
				if (refs.length == 0)
					{
					logMessage("Asset " + a_key + "/" + cookie_txt + " doesn't have any locator entries", MISManager.PRIORITY_WARNING);
					recordProblemFound(a_key, "Asset has cookie of " + cookie_txt + " but no locator entries");
					++num_problems;
					}
				else
					{
					for (int i = 0; i < refs.length; ++i)
						{
                        logMessage("asset ref: " + refs[i] + " for cookie " + a_cookie, MISManager.PRIORITY_DEBUG);
						MIMEFile the_binary = aa.getAsset(refs[i], a_cookie);
						if (the_binary == null)
							{
							logMessage("Failed to retrieve binary file for asset " + a_key + "/" + cookie_txt + " with locator " + refs[i], MISManager.PRIORITY_WARNING);
							recordProblemFound(a_key, "Failed to retrieve binary file for " + cookie_txt + "/type " + refs[i].type);
							++num_problems;
							}							
						}
					}
				}
			}
			
		return num_problems;
		}

	/* run checks against a set of assets */
	protected void doAssetChecks()
		{
		String sql_for_selection = null;
		
		JDBCPooledConnection pooledConn = null;
		Statement statement = null, statement2 = null;
		ResultSet rs = null, rs2 = null;
		int total_count = 0;
		UserModel um = new UserModel("Administrator");

		try
			{
			String expectedSystemID = DataSourceManager.getInstance().getSystemIDForSource("default"); // assume default data source
			String expectedDBID = DataSourceManager.getInstance().getDatabaseIDForSource("default");
			String expectedPrefix = expectedSystemID + expectedDBID;

			pooledConn = DatabaseUtils.getJDBCConnectionForPool("JDBC");
			// creating the statement with these options means only a subset of the results are read into memory so we can run large SQL results and just read as we need
			pooledConn .setAutoCommit(false);
		    statement = pooledConn.createStatement(ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY);
			statement.setFetchSize(1000);

			sql_for_selection = getConfigValue(PARAM_ASSET_SQL);			
			
			if (sql_for_selection == null)
				{
				String asset_selection = getConfigValue(PARAM_ASSET_SELECTION);
				if (asset_selection == null)
					asset_selection = "recent_pictures";

				// look up the SQL to use based upon the asset selection provided...this is either a built-in selection, or something configured in application preferences
				if (asset_selection.equalsIgnoreCase("recent_pictures"))
					sql_for_selection = "SELECT ASSET_ID FROM PICTURE WHERE CREATION_STAMP > " + VendorSpecificJDBC.getSQLDateByInterval(pooledConn.getConnection(), VendorSpecificJDBC.getSQLCurrDateFunc(pooledConn.getConnection()), "-", "DAY", "365");
				else if (asset_selection.equalsIgnoreCase("recent_stories"))
					sql_for_selection = "SELECT ASSET_ID FROM STORY WHERE CREATION_STAMP > " + VendorSpecificJDBC.getSQLDateByInterval(pooledConn.getConnection(), VendorSpecificJDBC.getSQLCurrDateFunc(pooledConn.getConnection()), "-", "DAY", "365");
				else if (asset_selection.equalsIgnoreCase("recent_media"))
					sql_for_selection = "SELECT ASSET_ID FROM MEDIA WHERE CREATION_STAMP > " + VendorSpecificJDBC.getSQLDateByInterval(pooledConn.getConnection(), VendorSpecificJDBC.getSQLCurrDateFunc(pooledConn.getConnection()), "-", "DAY", "365");
				else if (asset_selection.equalsIgnoreCase("recent_documents"))
					sql_for_selection = "SELECT ASSET_ID FROM DOCUMENT WHERE CREATION_STAMP > " + VendorSpecificJDBC.getSQLDateByInterval(pooledConn.getConnection(), VendorSpecificJDBC.getSQLCurrDateFunc(pooledConn.getConnection()), "-", "DAY", "365");
				else if (asset_selection.equalsIgnoreCase("recent_pages"))
					sql_for_selection = "SELECT ASSET_ID FROM PAGE WHERE CREATION_STAMP > " + VendorSpecificJDBC.getSQLDateByInterval(pooledConn.getConnection(), VendorSpecificJDBC.getSQLCurrDateFunc(pooledConn.getConnection()), "-", "DAY", "365");
				}
			
			String asset_checks_to_do = getConfigValue(PARAM_ASSET_CHECKS);
			if (asset_checks_to_do != null && asset_checks_to_do.equals(""))	// treat nothing being set same as null value
				asset_checks_to_do = null;
			if (asset_checks_to_do != null && asset_checks_to_do.equals("all"))	// treat "all" same as null value
				asset_checks_to_do = null;
				
			if (asset_checks_to_do == null)
				logMessage("Running all asset checks using " + sql_for_selection, MISManager.PRIORITY_INFO);
			else
				logMessage("Running asset checks (" + asset_checks_to_do + ") using " + sql_for_selection, MISManager.PRIORITY_INFO);			

			try
				{
				logMessage("Counting total assets to check...", MISManager.PRIORITY_INFO);
				setProcessMessage("Counting total assets to check...");
				String sql_for_count = sql_for_selection.replaceFirst("SELECT ASSET_ID", "SELECT COUNT(ASSET_ID)");
				sql_for_count = sql_for_count.replaceFirst("select asset_id", "select count(asset_id)");
				rs = statement.executeQuery(sql_for_count);
				if (rs.next())
					total_count = rs.getInt(1);
				rs.close();
				}
			catch (Exception e)
				{
				logMessage("Failed to get total count:" + e.getMessage(), MISManager.PRIORITY_WARNING);
				}
				
			rs = statement.executeQuery(sql_for_selection);
			int asset_num = 0, asset_failures = 0, binary_failures = 0;
			boolean hasMoreAssets = true;
			long start_time = System.currentTimeMillis();
			while (hasMoreAssets)
				{
                    long start_time_batch = System.currentTimeMillis();
				// for speed, we collect a set of asset IDs to process
				ArrayList<String> keys_for_batch = new ArrayList<String>();
				while (keys_for_batch.size() < ASSET_BATCH_SIZE && rs.next())
					keys_for_batch.add(rs.getString(1));

				if (keys_for_batch.size() < ASSET_BATCH_SIZE)
					hasMoreAssets = false;
				
				if (handleCurrentCommand() != ProcessModule.CONTINUE)
					hasMoreAssets = false;

                logMessage("Assets in batch: " + keys_for_batch, MISManager.PRIORITY_DEBUG);

				if (keys_for_batch.size() > 0)
					{
					if ((asset_num % 10000) == 0)
						{
						if (total_count == 0)
							logMessage("Checked " + asset_num + " assets....", MISManager.PRIORITY_INFO);
						else if (asset_num == 0)
							{
							logMessage("Checked " + asset_num + " assets out of " + total_count + "....", MISManager.PRIORITY_INFO);
							setProcessMessage("Checked " + asset_num + " assets out of " + total_count + "....");
							}
						else
							{
							long time_so_far = System.currentTimeMillis() - start_time;
							float time_per_item = ((float) time_so_far) / asset_num;
							float time_left = ((((float) total_count) - asset_num) * time_per_item) / 1000 / 60;
							logMessage("Checked " + asset_num + " assets out of " + total_count + " - estimate " + (int) time_left + "m remaining", MISManager.PRIORITY_INFO);
							setProcessMessage("Checked " + asset_num + " assets out of " + total_count + " - estimate " + (int) time_left + "m remaining");
							}
						}

					ArrayList<String> deleted_assets = new ArrayList<String>();
					HashMap<String,String> asset_owners = new HashMap<String, String>();
					if (asset_checks_to_do == null || asset_checks_to_do.contains("check-asset-table"))
						{
						// check primary key matches local system/database ID
						for (String a_key : keys_for_batch)
							{
							if (!a_key.substring(0, 8).equals(expectedPrefix))
								{
								logMessage("Primary key " + a_key + " doesn't have expected system/database ID of " + expectedPrefix, MISManager.PRIORITY_WARNING);
								recordProblemFound(a_key, "Invalid primary key format");
								}
							}
					
						// check ASSET table entry for each asset - LC status, origin, index status, owner, creator
						String sql_for_asset = "SELECT ASSET_ID,LIFECYCLE_STATUS,EMD_ICONS,OWNER_ID,ORIGIN FROM ASSET WHERE ASSET_ID IN (" + expandKeyList(keys_for_batch) + ")";
						try
							{
							statement2 = pooledConn.createStatement();
							rs2 = statement2.executeQuery(sql_for_asset);
							while (rs2.next())
								{
								String asset_id = rs2.getString(1);
								String lc_status = rs2.getString(2);
								String emd_icons = rs2.getString(3);
								String owner_id = rs2.getString(4);
								String origin_status = rs2.getString(5);
								
								asset_owners.put(asset_id, owner_id);

								if (lc_status == null)
									{
									logMessage("Asset " + asset_id + " doesn't have a lifecycle status set", MISManager.PRIORITY_WARNING);
									recordProblemFound(asset_id, "No lifecycle status");
									}
								else if (lc_status.equalsIgnoreCase("FEED") 
									|| lc_status.equalsIgnoreCase("CREATED") 
									|| lc_status.equalsIgnoreCase("ARCHIVE"))
									{
									// this is a normal status - nothing else to check
									}
								else if (lc_status.equalsIgnoreCase("PARKED"))
									{
									CollectionManager parking_coll = (CollectionManager) ResourceManager.getInstance().getResource("ParkingCollectionManager");
									PrimaryKey pk2 = new PrimaryKey(asset_id);
									PrimaryKeyManager.normalisePK(pk2);
									List parking_areas = parking_coll.getCollectionsContainingAsset(um, pk2);

									if (parking_areas.size() == 0)
										{
										logMessage("Asset " + asset_id + " has a lifecycle status of PARKED, but it not linked to a parking area", MISManager.PRIORITY_WARNING);
										recordProblemFound(asset_id, "Parked status but not in parking area");
										}
									else if (!origin_status.equalsIgnoreCase("FEED") && !origin_status.equalsIgnoreCase("CREATED"))
										{
										logMessage("Asset " + asset_id + " has a lifecycle status of PARKED, but doesn't have a valid origin lifecycle status", MISManager.PRIORITY_WARNING);
										recordProblemFound(asset_id, "Incorrect origin value for parked asset");
										}
									}
								else if (lc_status.equalsIgnoreCase("DELETED"))
									{
									deleted_assets.add(asset_id);
									}
								else
									{
									logMessage("Asset " + asset_id + " doesn't have a valid lifecycle status set (" + lc_status + ")", MISManager.PRIORITY_WARNING);
									recordProblemFound(asset_id, "Incorrect lifecycle status - " + lc_status);
									}
								
								// check EMD icons against the EMD tables
								if (asset_checks_to_do == null || asset_checks_to_do.contains("check-emd-icons"))
									{

									if (emd_icons != null && !emd_icons.equals(""))
										{
										List<String> emd_icon_list = emd_icons.toUpperCase().split(",");
										
										// load the full EMD data, look for icon fields being set, then check the EMD fields value for them...
										PrimaryKey pk = new PrimaryKey(asset_id);
										PrimaryKeyManager.normalisePK(pk);
										DataManager dm = (DataManager) ResourceManager.getInstance().getResource(DataManager.RESOURCE_NAME);
										DataObject full_data = dm.getDataObject(pk, true);
										HashMap<String,DataObject> kids = full_data.getChildren();
										Iterator<String> it = kids.keySet().iterator();
										while (it.hasNext())
											{
											String emd_type = it.next();
											DataObject emd_data = kids.get(emd_type);
											AttributesMap attributes = emd_data.getFields();
											Iterator<String> it2 = attributes.keySet().iterator();
											while (it2.hasNext())
												{
												String attr_name = it2.next();
												FieldInfo field_info = attributes.get(attr_name).getFieldInfo();
												if (field_info.getFieldType() == FieldInfo.MOGUL_TYPE_BOOLEAN)
													{
													String value = emd_data.getAttributeAsString(attr_name);
													if (PicdarBoolean.booleanValue(value))
														{
														String icon_id = field_info.getProperty(FieldInfo.PROPERTY_ICON_ID);
														if (icon_id != null && !icon_id.equals(""))
															{
															// then this string should be contained within the EMD list
															if (!emd_icon_list.contains(icon_id.toUpperCase()))
																{
																logMessage("Asset " + asset_id + " has a missing EMD icon (" + icon_id + ")", MISManager.PRIORITY_WARNING);
																recordProblemFound(asset_id, "Missing EMD icon - " + icon_id);
																}
															}
														}
													}
												}
											}
										}
									}

								if (owner_id != null)
									checkObjectOwner(asset_id, owner_id, "", "asset");							
								}
							
							for (String a_key : keys_for_batch)
								{
								if (!asset_owners.containsKey(a_key))
									{
									logMessage("Failed to find entry for " + a_key + " in the ASSET table.", MISManager.PRIORITY_WARNING);
									recordProblemFound(a_key, "Missing in ASSET table");
									}
								}
							}
                        catch (Exception e) {
                            logMessage("Error occured: " + e.getMessage(), MISManager.PRIORITY_ERROR);
                        }
						finally
							{
							rs2.close();
							statement2.close();
							}
						}
						
					// check typical fields - creation/update stamp, created by/modified by, etc 
					// group the keys together by type as we need to collect data from different tables
                    ArrayList<String> mainAssetRecord = new ArrayList<String>();
					HashMap<String, ArrayList<String>> keysByType = new HashMap<String, ArrayList<String>>();
					for (String a_key : keys_for_batch)
						{
						PrimaryKey pk = new PrimaryKey(a_key);
						PrimaryKeyManager.normalisePK(pk);
						String type_for_key = PrimaryKeyManager.getTableFor(pk);
						ArrayList<String> keys_for_type = keysByType.get(type_for_key);
						if (keys_for_type == null)
							{
							keys_for_type = new ArrayList<String>();
							keysByType.put(type_for_key, keys_for_type);
							}
						keys_for_type.add(a_key);
						}
					for (String type : keysByType.keySet())
						{
						ArrayList<String> keys_for_type = keysByType.get(type);
						if (asset_checks_to_do == null || asset_checks_to_do.contains("check-asset-fields"))
							{
							String sql_for_asset = "SELECT ASSET_ID,CREATION_STAMP,UPDATE_STAMP FROM " + type + " WHERE ASSET_ID IN (" + expandKeyList(keys_for_type) + ")";
								
							try
								{
								statement2 = pooledConn.createStatement();
								rs2 = statement2.executeQuery(sql_for_asset);

                                // This is a bug because the now time is not being set for each row, so it could be out of date by the end of the result set
                                // For now, I added an offset of 5 minutes to make sure that it covered these
                                // Not sure of the performance impact to initialise "now" variable for each resultset.
                                java.util.Date now = DatabaseUtils.getSystemDate();
								while (rs2.next())
									{
									String asset_id = rs2.getString(1);
									Date creation_stamp = rs2.getDate(2);
									Date update_stamp = rs2.getDate(3);
										
									if (creation_stamp == null)
										{
										logMessage("Asset " + asset_id + " doesn't have a creation stamp set.", MISManager.PRIORITY_WARNING);
										recordProblemFound(asset_id, "No creation stamp");
										}
									else if (isAfterDateCheck(creation_stamp, now))
										{
                                            // Perform a secondary check for an offset of 2 minutes
                                            logMessage("Asset " + asset_id + " has a creation stamp set set in the future.", MISManager.PRIORITY_WARNING);
                                            recordProblemFound(asset_id, "Future creation stamp");
										}
									if (update_stamp == null)
										{
                                            logMessage("Asset " + asset_id + " doesn't have an update stamp set.", MISManager.PRIORITY_WARNING);
                                            recordProblemFound(asset_id, "No update stamp");
										}
									else if (isAfterDateCheck(update_stamp,now)) // Checking with an offset of 1 minute as the DB timestamp to the app
										{
                                            logMessage("Asset " + asset_id + " has an update stamp set set in the future.", MISManager.PRIORITY_WARNING);
                                            recordProblemFound(asset_id, "Future update stamp");
										}

                                        mainAssetRecord.add(asset_id);
									}

                                    for (String a_key : keys_for_type)
                                    {
                                        if (!mainAssetRecord.contains(a_key))
                                        {
                                            logMessage("Failed to find entry for " + a_key + " in the " + type + " table.", MISManager.PRIORITY_WARNING);
                                            recordProblemFound(a_key, "Missing in " + type + " table");
                                        }
                                    }

								}
							finally
								{
								rs2.close();
								statement2.close();
								}
							}
						
						// only check policies when also checking the asset table - as we need the owners loaded
						if (asset_checks_to_do == null || asset_checks_to_do.contains("check-policies"))
							{					
							for (String a_key : keys_for_batch)
								checkObjectPolicies(a_key, a_key, "asset", asset_owners.get(a_key));
							}

                            // Check the stories will pass antisamy parameter validation
                            if ((asset_checks_to_do == null || asset_checks_to_do.contains("check-story-antisamy")) && type.equals("STORY"))
                            {
                                setProcessMessage("Running checks on story antisamy");
                                for (String a_key : keys_for_batch)
                                    checkStoryAntiSamyValidation(a_key);
                            }

                            // Check the linked assets associated to the asset
                            if (asset_checks_to_do == null || asset_checks_to_do.contains("check-linked-assets"))
                            {
                                setProcessMessage("Running checks on LINKED_ASSET");
                                for (String a_key : keys_for_batch)
                                    checkAssociatedTables(a_key, "LINKED_ASSET","ASSET_ID, LINK_TO, LINK_ID, CREATION_STAMP ,SEGMENTS, TIMESTAMP, TYPE, NAME", "LINK_ID");
                            }
						}

					if (asset_checks_to_do == null || asset_checks_to_do.contains("check-asset-files"))
						{
						String types_to_retrieve = getConfigValue(PARAM_ASSET_TYPES_TO_RETRIEVE);
						if (types_to_retrieve != null && !types_to_retrieve.equals("") && !types_to_retrieve.equalsIgnoreCase("none"))
							{
							try
								{
								binary_failures += checkAssetFiles(keys_for_batch, types_to_retrieve);
								}
							catch (Exception e)
								{
								logMessage("Error while checking binary files:" + e.getMessage(), MISManager.PRIORITY_ERROR);
								throw e;
								}
							}
						}

					if (asset_checks_to_do == null || asset_checks_to_do.contains("check-index"))
						{					
						// check items are indexed
						try
							{
							asset_failures += checkIndexStatus(keys_for_batch);
							}
						catch (Exception e)
							{
							logMessage("Error while checking assets against index:" + e.getMessage(), MISManager.PRIORITY_ERROR);
							throw e;
							}
						}										
					}

				asset_num += keys_for_batch.size();
                logMessage("Batch of " + keys_for_batch.size() + " assets - took " + (System.currentTimeMillis() - start_time_batch) / 1000 + "s", MISManager.PRIORITY_INFO);
                logMessage("Processed " + asset_num + " assets so far", MISManager.PRIORITY_INFO);
				}
			
			logMessage("Finished checking " + asset_num + " assets - took " + (System.currentTimeMillis() - start_time) / 1000 + "s", MISManager.PRIORITY_INFO);
			if (asset_checks_to_do == null || asset_checks_to_do.contains("check-index"))
				logMessage("Found " + asset_failures + " assets missing from the SOLR index", MISManager.PRIORITY_INFO);
			if (asset_checks_to_do == null || asset_checks_to_do.contains("check-asset-files"))
				logMessage("Found " + binary_failures + " problems with binary files", MISManager.PRIORITY_INFO);
			}
		catch (SQLException | ResourceException e)
			{
			logMessage("Error while checking assets :" + e.getMessage(), MISManager.PRIORITY_ERROR);
			}
		finally
			{
			try
				{
				if (rs != null)
					rs.close();
				if (statement != null)
					statement.close();
				if (pooledConn != null)
					pooledConn.release();
				}
			catch (Exception e)
				{
				logMessage("Failed to tidy up after previous error:" + e.getMessage() , MISManager.PRIORITY_ERROR);
				}
			}	
		}
	
	/* run checks against index - this runs a SOLR search and checks results are in database */
	protected void doIndexChecks()
		{
		String index_search = getConfigValue(PARAM_ASSET_SEARCH);			

		if (index_search == null)
			index_search = "_isparent_bool:1";

		PoolManager pm = (PoolManager) ResourceManager.getInstance().getResource(PoolManager.RESOURCE_NAME);
		SolrConnectionPool solr_pool = (SolrConnectionPool) pm.getPool("SolrCloud");
		SolrPooledConnection searchPool = (SolrPooledConnection) solr_pool.get("Index sanity checks");

		QueueManager qm = ResourceManager.getInstance().getResource("BacklogIndexQueueManager");
		Queue index_queue = qm.getQueue("MM_INDEX_QUEUE");

		JDBCPooledConnection pooledConn = DatabaseUtils.getJDBCConnectionForPool("JDBC");
		Statement statement = pooledConn.createStatement();
		ResultSet rs = null;

		try
			{
			SolrPreparedQuery query = new SolrPreparedQuery("assets", null, index_search, null, "doc_id desc");
			SolrSearchResponse resp = searchPool.search(query, SolrPooledConnection.SOLR_STARTING_CURSOR_MARK, ASSET_BATCH_SIZE);
			List<String> search_keys = resp.getKeys();

			// get sets of keys and compare against database
			int asset_num = 0;
			int results_pos = 0;
			while (search_keys.size() > 0 && handleCurrentCommand() == ProcessModule.CONTINUE)
				{
				List<String> thousand_keys = new ArrayList<String>();
				while (results_pos < search_keys.size() && thousand_keys.size() < ASSET_BATCH_SIZE)
					{
					String a_key = search_keys.get(results_pos++);
					thousand_keys.add(a_key.replace(":0", ""));
					}

				if (thousand_keys.size() == 0)
					{
					String marker = resp.getNextCursorMark();
					resp = searchPool.search(query, marker, ASSET_BATCH_SIZE);
					search_keys = resp.getKeys();
					results_pos = 0;
					}
				else
					{
					String sql = "SELECT ASSET_ID FROM ASSET WHERE ASSET_ID IN (";			
					for (int i = 0; i < thousand_keys.size(); ++i)
						{
						if (i > 0)
							sql += ",";
						sql += "'" + thousand_keys.get(i) + "'";
						}
					sql += ")";
					
					HashMap keysFound = new HashMap();
					rs = statement.executeQuery(sql);
					while (rs.next())
						keysFound.put(rs.getString(1), rs.getString(1));
					rs.close();
					
					for (int i = 0; i < thousand_keys.size(); ++i)
						{
						String search_key = thousand_keys.get(i);
						String lookup = keysFound.get(search_key);
						if (lookup == null)
							{
							logMessage("Failed to find entry for key " + search_key + " in database (ASSET table)",  MISManager.PRIORITY_WARNING);	
							// add into the indexing queue
							index_queue.addItem(search_key, "index", 0, "Administrator", null);
							}
						}			
						
					asset_num += thousand_keys.size();
					if ((asset_num % 10000) == 0)
						{
						logMessage("Checked " + asset_num + " assets....", MISManager.PRIORITY_INFO);
						setProcessMessage("Checked " + asset_num + " assets....");
						}
					}								
				}
			logMessage("Finished checking " + asset_num + " assets....", MISManager.PRIORITY_INFO);
			}
		finally
			{
			statement.close();
			pooledConn.release();
			searchPool.release();
			}
		}

	/* run some sanity checks against index for items that appear in the index but are invalid
	 */
	protected void doIndexSanityChecks()
		{
		setProcessMessage("Running sanity checks against index....");

		// this search is for everything minus anything where _isparent_bool is true or false
		// logically this should not return anything, but we've found it to give results if index documents are invalids
		String index_search = "*:* NOT (_isparent_bool:true OR _isparent_bool:false)";

		PoolManager pm = (PoolManager) ResourceManager.getInstance().getResource(PoolManager.RESOURCE_NAME);
		SolrConnectionPool solr_pool = (SolrConnectionPool) pm.getPool("SolrCloud");
		SolrPooledConnection searchPool = (SolrPooledConnection) solr_pool.get("Index sanity checks");
		
		try
			{
			SolrPreparedQuery query = new SolrPreparedQuery("assets", null, index_search, null, "doc_id desc");
			SolrSearchResponse resp = searchPool.search(query, SolrPooledConnection.SOLR_STARTING_CURSOR_MARK, ASSET_BATCH_SIZE);
			List<String> search_keys = resp.getKeys();
			QueueManager qm = ResourceManager.getInstance().getResource("BacklogIndexQueueManager");
			Queue index_queue = qm.getQueue("MM_INDEX_QUEUE");
	
			for (int i = 0; i < search_keys.size(); ++i)
				{
				String a_key = search_keys.get(i).replace(":0", "");
				logMessage("Document " + a_key + " in the assets index appears to be invalid",  MISManager.PRIORITY_WARNING);
				// add into the indexing queue
				index_queue.addItem(a_key, "index", 0, "Administrator", null);
				}			
							
			logMessage("Finished checking for invalid index documents - found " + search_keys.size() + " problem documents", MISManager.PRIORITY_INFO);
	
			// another test that facets on doc_id with a threshold of 2. This should always return nothing - any results implies that there are duplicate keys in the index
			Map<String, String> solrFieldsMap = new HashMap<>();
			solrFieldsMap.put("doc_id", "doc_id");
			query = new SolrPreparedQuery("assets", null, "*:*", null, "doc_id desc");
			TopTermContainer topTerms = searchPool.getTopTerms(query, null, solrFieldsMap, -1, 2);
			for (int i = 0; i < topTerms.getElementCount("doc_id"); ++i)
				{
				String doc_id = topTerms.getTermValue("doc_id", i);
				String a_key = doc_id.replace(":0", "");
				logMessage("Document " + a_key + " in the assets index appears more than once",  MISManager.PRIORITY_WARNING);
				// add into the indexing queue
				index_queue.addItem(a_key, "index", 0, "Administrator", null);
				}						
			logMessage("Finished checking for duplicate index documents - found " + topTerms.getElementCount("doc_id") + " problem documents", MISManager.PRIORITY_INFO);
			}
		finally
			{
			searchPool.release();
			}
		}		

	protected void doUserChecks()
		{
		logMessage("Running user checks..." , MISManager.PRIORITY_INFO);
		setProcessMessage("Running user checks....");

		JDBCPooledConnection pooledConn = null;
		Statement statement = null;
		ResultSet rs = null;
		try
			{
			pooledConn = DatabaseUtils.getJDBCConnectionForPool("JDBC");
			statement = pooledConn.createStatement();
			
			String sql = "SELECT USER_ID,NAME,STATUS,LOGIN_COUNT FROM MM_USER";			
			rs = statement.executeQuery(sql);
			int userNum = 0, numActive = 0, numInactive = 0;
			while (rs.next())
				{
				String user_id = rs.getString(1);
				String user_name = rs.getString(2);
				String user_status = rs.getString(3);
				String login_count = rs.getString(4);

				if (user_status.equalsIgnoreCase("ACTIVE"))
					numActive++;
				else  if (user_status.equalsIgnoreCase("INACTIVE") || user_status.equalsIgnoreCase("REJECT") || user_status.equalsIgnoreCase("NOT_AGREED"))
					numInactive++;
				else
					{
					logMessage("User " + user_name + " doesn't have a valid status of " + user_status, MISManager.PRIORITY_WARNING);
					recordProblemFound(user_name, "Invalid status - " + user_status);
					}

				// check user preferences/preference templates valid
				UserManager um = (UserManager) ResourceManager.getInstance().getResource(UserManager.RESOURCE_NAME);
				try
					{
					String chpPrefs = um.getUserPreferences(user_name, PanelBasedApplication.CHP);
					if (!XMLUtils.isWellformedXML(chpPrefs))
						{
						logMessage("CHP preferences for user " + user_name + " is not well formed", MISManager.PRIORITY_WARNING);
						recordProblemFound(user_name, "Not well formed CHP preferences XML");
						}
					}
				catch (UserManagerException e)
					{
					logMessage("Failed to get CHP preferences for user " + user_name + " but this will automatically be added when the user logs into CHP/CHPSysMgt", MISManager.PRIORITY_WARNING);
					recordProblemFound(user_name, "Failed to get CHP preferences but this will automatically be added when the user logs into CHP/CHPSysMgt");
					}
				// checking CHPSysMgt prefs is removed for now, as most users aren't expected to have these and it log errors for each
				if (false)
					{
					try
						{
						String chpSMPrefs = um.getUserPreferences(user_name, PanelBasedApplication.CHPSysMgt);
						if (!XMLUtils.isWellformedXML(chpSMPrefs))
							{
							logMessage("CHPSysMgt preferences for user " + user_name + " is not well formed", MISManager.PRIORITY_WARNING);
							recordProblemFound(user_name, "Not well formed CHPSysMgt preferences XML");
							}
						}
					catch (UserManagerException e)
						{
						logMessage("Failed to get CHPSysMgt preferences for user " + user_name, MISManager.PRIORITY_WARNING);
						recordProblemFound(user_name, "Failed to get CHPSysMgt preferences");
						}
					}
				
				// check user profile is valid - just check full name is set
				DataObject user_do = um.getUserProfile(user_name);
				String full_name = user_do.getAttributeAsString("contact");
				if ((full_name == null || full_name.equals("")) && !user_name.equalsIgnoreCase("Administrator"))
					{
					logMessage("User " + user_name + " has no fullname user profile value set", MISManager.PRIORITY_WARNING);
					recordProblemFound(user_name, "User doesn't have fullname user profile set");
					}					
				
				// check personal folder for user (does it exist, ownership set OK)
				HierarchyNode users_personal_folder = null;
				HierarchicalDB personals = (HierarchicalDB) ResourceManager.getInstance().getResource(HierarchicalDB.RESOURCE_NAME);
				try
					{
					HierarchyOptions opts = new HierarchyOptions();
					opts.setPath("/" + user_name);
					users_personal_folder = personals.getNode(opts, "shelf");
					}
				catch (Exception e)
					{
					}

				if (users_personal_folder == null)
					{
					if (Integer.parseInt(login_count) != 0)
						{
						logMessage("Failed to find personal folder for " + user_name + " (may be OK if user only ever accesses CHPSysMgt)", MISManager.PRIORITY_WARNING);
						recordProblemFound(user_name, "Failed to find personal folder (may be OK if user only ever accesses CHPSysMgt)");
						}
					}								
				else
					{
					// the top level personal folder for the user doesn't have the owner ID set, but all children should...
					HierarchyOptions opts = new HierarchyOptions();
					opts.setNodeId(users_personal_folder.getPrimaryKey().getKey());
					HierarchyNodeSet pers_folders = personals.getAllChildrenNodes(opts, "shelf");
					int expected_owner = Integer.parseInt(user_id);
					for (int i = 0; i < pers_folders.size(); ++i)
						{
						HierarchyNode a_pers_folder = pers_folders.get(i);
						if (a_pers_folder.getAttributeAsInt("OWNER_ID", -1) != expected_owner)
							{
							logMessage("Personal folder with ID " + a_pers_folder.getPrimaryKey() + " for user '" + user_name + "' doesn't have the owner (" + a_pers_folder.getAttributeAsString("OWNER_ID") + ") set to the ID of the user (" + expected_owner + ")", MISManager.PRIORITY_WARNING);
							recordProblemFound(user_name, "Personal folder " + a_pers_folder.getPrimaryKey() + " has wrong owner (" + a_pers_folder.getAttributeAsString("OWNER_ID") + " instead of " + expected_owner + ")");
							}				
						}
					}

				++userNum;
				}
			logMessage("Finished checking " + userNum + " user accounts (" + numActive + " active accounts, " + numInactive + " inactive)", MISManager.PRIORITY_INFO);
			}
		catch (SQLException | ResourceException e)
			{
			logMessage("Failed to perform user checks:" + e.getMessage() + "." , MISManager.PRIORITY_ERROR);
			}
		finally
			{
			try
				{
				if (rs != null)
					rs.close();
				if (statement != null)
					statement.close();
				if (pooledConn != null)
					pooledConn.release();
				}
			catch (Exception e)
				{
				logMessage("Failed to tidy up after previous error:" + e.getMessage() , MISManager.PRIORITY_ERROR);
				}
			}
		}
	
	protected void doPublicationChecks()
		{
		logMessage("Running publication checks..." , MISManager.PRIORITY_INFO);
		setProcessMessage("Running publication checks....");

		// check default owners are valid
		JDBCPooledConnection pooledConn = null;
		Statement statement = null;
		ResultSet rs = null;
		HashMap<String, String> pubGroups = new HashMap<String, String>();
		HashMap<String, String> pubNames = new HashMap<String, String>();
		try
			{
			pooledConn = DatabaseUtils.getJDBCConnectionForPool("JDBC");
			statement = pooledConn.createStatement();
			
			String sql = "SELECT NAME,DEFAULT_OWNER,TYPE FROM PUBLICATION";			
			rs = statement.executeQuery(sql);
			int pubCount = 0;
			while (rs.next())
				{
				String pub_name = rs.getString(1);
				String default_group = rs.getString(2);
				String pub_type = rs.getString(3);

				pubNames.put(pub_name, pub_name);

				if (default_group != null && !default_group.equals(""))
					checkObjectOwner("(title is primary key)", default_group, pub_name, "publication");

                if(pub_type == null) {
                    logMessage("Publication '" + pub_name + "' does not have a type", MISManager.PRIORITY_WARNING);
                    recordProblemFound(pub_name, "Publication type is blank");
                } else if (!pub_type.equalsIgnoreCase("date") &&
					!pub_type.equalsIgnoreCase("issue") &&
					!pub_type.equalsIgnoreCase("web") &&
					!pub_type.equalsIgnoreCase("syndication"))
					{
					logMessage("Publication '" + pub_name + "' doesn't have a valid type (" + pub_type + ")", MISManager.PRIORITY_WARNING);
					recordProblemFound(pub_name, "Publication type of " + pub_type + " is not valid");
					}

				++pubCount;
				}
			logMessage("Finished checking " + pubCount+ " publications", MISManager.PRIORITY_INFO);
			}
		catch (SQLException | ResourceException e)
			{
			logMessage("Failed to perform publication checks:" + e.getMessage() + "." , MISManager.PRIORITY_ERROR);
			}
		finally
			{
			try
				{
				if (rs != null)
					rs.close();
				if (statement != null)
					statement.close();
				if (pooledConn != null)
					pooledConn.release();
				}
			catch (Exception e)
				{
				logMessage("Failed to tidy up after previous error:" + e.getMessage() , MISManager.PRIORITY_ERROR);
				}
			}

		// get list of publication groups
		try
			{
			pooledConn = DatabaseUtils.getJDBCConnectionForPool("JDBC");
			statement = pooledConn.createStatement();
			
			String sql = "SELECT NAME FROM PUBLICATION_GROUP";			
			rs = statement.executeQuery(sql);
			while (rs.next())
				{
				String pub_group_name = rs.getString(1);
				pubGroups.put(pub_group_name, pub_group_name);
				}
			}
		catch (SQLException | ResourceException e)
			{
			logMessage("Failed to load publication group names", MISManager.PRIORITY_ERROR);
			}
		finally
			{
			try
				{
				if (rs != null)
					rs.close();
				if (statement != null)
					statement.close();
				if (pooledConn != null)
					pooledConn.release();
				}
			catch (Exception e)
				{
				logMessage("Failed to tidy up after previous error:" + e.getMessage() , MISManager.PRIORITY_ERROR);
				}
			}

 		// check publication groups, just check there aren't any pubs outside groups
		try
			{
			pooledConn = DatabaseUtils.getJDBCConnectionForPool("JDBC");
			statement = pooledConn.createStatement();
			
			String sql = "SELECT PUBLICATION_GROUP_NAME,PUBLICATION_NAME FROM PUBLICATION_GROUP_LINK";			
			rs = statement.executeQuery(sql);
			int pubLinks = 0;
			while (rs.next())
				{
				String pub_group_name = rs.getString(1);
				String pub_name = rs.getString(2);

				if (!pubNames.containsKey(pub_name))
					{
					logMessage("Publication group links contains an entry for publication '" + pub_name + "' that doesn't exist", MISManager.PRIORITY_WARNING);
					recordProblemFound(pub_group_name, "Publication " + pub_name + " doesn't exist");
					}

				if (!pubGroups.containsKey(pub_group_name))
					{
					logMessage("Publication group links contains an entry for publication group '" + pub_group_name + "' that doesn't exist", MISManager.PRIORITY_WARNING);
					recordProblemFound(pub_group_name, "Publication group doesn't exist, but is referenced in link table");
					}

				++pubLinks;
				}
			logMessage("Finished checking " + pubLinks + " publication group links", MISManager.PRIORITY_INFO);
			}
		catch (SQLException | ResourceException e)
			{
			logMessage("Failed to perform publication group checks:" + e.getMessage() + "." , MISManager.PRIORITY_ERROR);
			}
		finally
			{
			try
				{
				if (rs != null)
					rs.close();
				if (statement != null)
					statement.close();
				if (pooledConn != null)
					pooledConn.release();
				}
			catch (Exception e)
				{
				logMessage("Failed to tidy up after previous error:" + e.getMessage() , MISManager.PRIORITY_ERROR);
				}
			}

 		// check editions, make sure all linked into valid publications, check parent IDs are valid
 		HashMap<Integer, String> editions = new HashMap<Integer, String>();
 		HashMap<Integer, Integer> parent_editions = new HashMap<Integer, Integer>();
		try
			{
			pooledConn = DatabaseUtils.getJDBCConnectionForPool("JDBC");
			statement = pooledConn.createStatement();
			
			String sql = "SELECT EDITION_ID,NAME,PUBLICATION_NAME,PARENT_ID FROM EDITION";
			rs = statement.executeQuery(sql);
			int pubEditions = 0;
			while (rs.next())
				{
				int ed_id = rs.getInt(1);
				String ed_name = rs.getString(2);
				String pub_name = rs.getString(3);
				String parent_id = rs.getInt(4);

				editions.put(new Integer(ed_id), ed_name);
				if (parent_id != null)
					editions.put(new Integer(ed_id), new Integer(parent_id));

				if (!pubNames.containsKey(pub_name))
					{
					logMessage("Edition " + ed_id + "/" + ed_name + " is for publication '" + pub_name + "' that doesn't exist", MISManager.PRIORITY_WARNING);
					recordProblemFound(Integer.toString(ed_id), "Edition refers to publication that doesn't exist");
					}

				++pubEditions;
				}
			
			// now check that all of the parent_ids were found
			for (Integer ed_id : parent_editions.keySet())
				{
				Integer parent_id = parent_editions.get(ed_id);
				if (!editions.containsKey(parent_id))
					{
					logMessage("Edition " + ed_id + " has parent ID of " + parent_id + " that doesn't exist", MISManager.PRIORITY_WARNING);
					recordProblemFound(Integer.toString(ed_id), "Edition refers to parent ID " + parent_id + " that doesn't exist");
					}
				}
				
			logMessage("Finished checking " + pubEditions + " editions", MISManager.PRIORITY_INFO);
			}
		catch (SQLException | ResourceException e)
			{
			logMessage("Failed to perform publication group checks:" + e.getMessage() + "." , MISManager.PRIORITY_ERROR);
			}
		finally
			{
			try
				{
				if (rs != null)
					rs.close();
				if (statement != null)
					statement.close();
				if (pooledConn != null)
					pooledConn.release();
				}
			catch (Exception e)
				{
				logMessage("Failed to tidy up after previous error:" + e.getMessage() , MISManager.PRIORITY_ERROR);
				}
			} 		
		}
	
	protected void doListChecks()
		{
		logMessage("Running list checks..." , MISManager.PRIORITY_INFO);
		setProcessMessage("Running list checks....");

		// lists are really just hierarchys (mostly with a single level)
		// the following only includes lists that are actively used by CHP
		doFolderChecks( "SUPPLIER", null, "SUPPLIER", false, true);
		doFolderChecks( "KEYWORDS", null, "KEYWORDS", false, false);
		doFolderChecks( "STORY_KEYWORDS", null, "STORY_KEYWORDS", false, false);
		doFolderChecks( "LOAD_SOURCE", null, "LOAD_SOURCE", false, false);
		doFolderChecks( "PROVIDERS", null, "PROVIDERS", false, false);
		doFolderChecks( "COPYRIGHT", null, "COPYRIGHT", false, false);
		doFolderChecks( "PLATFORMS", null, "PLATFORMS", false, false);
		doFolderChecks( "BYLINE", null, "BYLINE", false, false);
		doFolderChecks( "BIOGRAPHY", null, "BIOGRAPHY", false, false);
		doFolderChecks( "COUNTRIES", null, "COUNTRIES", false, false);
		doFolderChecks( "MOODS", null, "MOODS", false, false);
		doFolderChecks( "PEOPLE", null, "PEOPLE", false, false);
		doFolderChecks( "PHOTOGRAPHERS", null, "PHOTOGRAPHERS", false, false);
		doFolderChecks( "SOURCE", null, "SOURCE", false, false);
		doFolderChecks( "EXCLUDED_FACETS", null, "EXCLUDED_FACETS", false, false);
		doFolderChecks( "CHANNELS", null, "CHANNELS", false, true);
		doFolderChecks( "EXTERNAL_CATEGORIES", null, "EXTERNAL_CATEGORIES", false, false);
		doFolderChecks( "EXTERNAL_KEYWORDS", null, "EXTERNAL_KEYWORDS", false, false);
		doFolderChecks( "NOSHARE_BYLINES", null, "NOSHARE_BYLINES", false, false);
		doFolderChecks( "NOSHARE_TITLES", null, "NOSHARE_TITLES", false, false);
		doFolderChecks( "FORBIDDEN_WORDS", null, "FORBIDDEN_WORDS", false, false);
		doFolderChecks( "SEARCH_WARNING_TERMS", null, "SEARCH_WARNING_TERMS", false, false);
		}
	
	/* helper function to check if a named database object exists */
	protected boolean does_object_exist(String table, String key, String value)
		{
		JDBCPooledConnection pooledConn = null;
		Statement statement = null;
		ResultSet rs = null;
		int itemCount = 0;
		try
			{
			pooledConn = DatabaseUtils.getJDBCConnectionForPool("JDBC");
			statement = pooledConn.createStatement();
			String sql = "SELECT COUNT(1) FROM " + table + " WHERE " + key + "='" + value + "'";
			
			// count the folders so we can show progress
			rs = statement.executeQuery(sql);
			rs.next();
			itemCount = rs.getInt(1);
			}
		catch (SQLException | ResourceException e)
			{
			logMessage("Failed to perform database object check" + e.getMessage() , MISManager.PRIORITY_ERROR);
			}
		finally
			{
			try
				{
				if (rs != null)
					rs.close();
				if (statement != null)
					statement.close();
				if (pooledConn != null)
					pooledConn.release();
				}
			catch (Exception e)
				{
				logMessage("Failed to tidy up after previous error:" + e.getMessage() , MISManager.PRIORITY_ERROR);
				}
			}
			
		return (itemCount == 1);
		}
	
	protected void doProcessChecks()
		{
		logMessage("Running process checks..." , MISManager.PRIORITY_INFO);
		setProcessMessage("Running process checks....");
		
		JDBCPooledConnection pooledConn = null;
		Statement statement = null;
		ResultSet rs = null;

		// check process templates
		try
			{
			pooledConn = DatabaseUtils.getJDBCConnectionForPool("JDBC");
			statement = pooledConn.createStatement();
			String sql = "SELECT NODE_ID,KEY,VALUE FROM PROCESS_TEMPLATES";
			rs = statement.executeQuery(sql);
			while (rs.next())
				{
				String template_id = rs.getString(1);
				String template_name = rs.getString(2);
				String template_content = rs.getString(3);
				
				if (template_id.equals("-1"))
					{
					// do nothing
					}
				else
					{
					if (!template_content.startsWith("<?xml"))
						{
						// then it may just be an XML fragment included elsewhere...XMLize it
						template_content = "<?xml version=\"1.0\"?><top_level>" + template_content + "</top_level>";
						}

					if (!XMLUtils.isWellformedXML(template_content))
						{
						logMessage("XML configuration for process template " + template_name + " is not well formed", MISManager.PRIORITY_WARNING);
						recordProblemFound(template_name, "Invalid process template XML");
						}
					}
				}
			}
		catch (SQLException | ResourceException e)
			{
			logMessage("Failed to perform process template checks" + e.getMessage() , MISManager.PRIORITY_ERROR);
			}
		finally
			{
			try
				{
				if (rs != null)
					rs.close();
				if (statement != null)
					statement.close();
				if (pooledConn != null)
					pooledConn.release();
				}
			catch (Exception e)
				{
				logMessage("Failed to tidy up after previous error:" + e.getMessage() , MISManager.PRIORITY_ERROR);
				}
			}		
		
		// get each process and check that the configuration is valid...
		// is the XML configuration for it valid. Does the template exist and expand OK?
		// if template is filled in, does it match the config and exist 
		// does configured app group exist?
		try
			{
			pooledConn = DatabaseUtils.getJDBCConnectionForPool("JDBC");
			statement = pooledConn.createStatement();
			String sql = "SELECT CLASS,TYPE,NAME,APP_GROUP,CONFIG_XML,TEMPLATE,STATUS FROM MM_PROCESS_INFO";
			
			rs = statement.executeQuery(sql);
			while (rs.next())
				{
				String process_class = rs.getString(1);
				String process_type = rs.getString(2);
				String process_name = rs.getString(3);
				String process_app_group = rs.getString(4);
				String process_config = rs.getString(5);
				String process_template = rs.getString(6);
                String process_status = rs.getString(7);
				
				// first of all, check the XML
				if (!XMLUtils.isWellformedXML(process_config))
					{
					logMessage("XML configuration for process " + process_class + "/" + process_type + "/" + process_name + " is not well formed", MISManager.PRIORITY_WARNING);
					recordProblemFound(process_class + "/" + process_type + "/" + process_name, "Invalid process XML");
					}
				else
					{
					Document xml_doc = XMLUtils.parseDocument(process_config);
					
					String configured_app_group = XMLUtils.evaluatePathAsValue(xml_doc, "//properties/APP_GROUP");
					String configured_template = XMLUtils.evaluatePathAsValue(xml_doc, "//properties/TEMPLATE");

					if (configured_app_group)
						{
                        logMessage("configured_app_group:'" + configured_app_group + "';process_app_group:'" + process_app_group + "'", MISManager.PRIORITY_DEBUG);
						if (!configured_app_group.equals(process_app_group))
							{
							logMessage("Process " + process_class + "/" + process_type + "/" + process_name + " has an APP_GROUP configured that doesn't match the database value", MISManager.PRIORITY_WARNING);
							recordProblemFound(process_class + "/" + process_type + "/" + process_name, "Mismatched APP_GROUP value for process");
							}
						else if (!does_object_exist("APPLICATION_GROUPS", "GROUP_NAME", configured_app_group) && !does_object_exist("APP_GROUPS_SECURE", "GROUP_NAME", configured_app_group))
							{
							logMessage("Process " + process_class + "/" + process_type + "/" + process_name + " refers to APP_GROUP " + configured_app_group + " that doesn't exist", MISManager.PRIORITY_WARNING);
							recordProblemFound(process_class + "/" + process_type + "/" + process_name, "Missing APP_GROUP entry for process");
							}
						}
						
					if (configured_template)
						{
						if (!configured_template.equals(process_template))
							{
							logMessage("Process " + process_class + "/" + process_type + "/" + process_name + " has a TEMPLATE configured that doesn't match the database value", MISManager.PRIORITY_WARNING);
							recordProblemFound(process_class + "/" + process_type + "/" + process_name, "Mismatched TEMPLATE value for process");
							}
						else if (!does_object_exist("PROCESS_TEMPLATES", "KEY", configured_template))
							{
							logMessage("Process " + process_class + "/" + process_type + "/" + process_name + " refers to TEMPLATE " + configured_template + " that doesn't exist", MISManager.PRIORITY_WARNING);
							recordProblemFound(process_class + "/" + process_type + "/" + process_name, "Missing TEMPLATE entry for process");
							}
						}

					// do rest of checks against the fully expanded XML
					String full_config = null;
					try
						{
						full_config = ProcessUtils.expandProcessConfig(process_config);
						}
					catch (Exception e)
						{
						logMessage("Error expanding config" + e.getMessage(), MISManager.PRIORITY_DEBUG);
						}
					if (full_config == null)
						{
                            if(process_status.equalsIgnoreCase("BLOCKED")) {
                                logMessage("The config for process " + process_class + "/" + process_type + "/" + process_name + " could not be expanded but the process is blocked", MISManager.PRIORITY_WARNING);
                                recordProblemFound(process_class + "/" + process_type + "/" + process_name, "Failed to expand configuration (BLOCKED process)");
                            } else {
                                logMessage("The config for process " + process_class + "/" + process_type + "/" + process_name + " could not be expanded", MISManager.PRIORITY_WARNING);
                                recordProblemFound(process_class + "/" + process_type + "/" + process_name, "Failed to expand configuration");
                            }
						}
					else
						{
						xml_doc = XMLUtils.parseDocument(full_config);
	
						ArrayList transformerNames = XMLUtils.evaluatePathAsValueList(xml_doc, "//modules/module/class[text()=\"com.picdar.process2.Processing.XMLTransformer.XMLTransformer\"]/../config/transform/@name");
						for (int i = 0; i < transformerNames.size(); ++i)
							{
							if (!does_object_exist("TRANSFORMER", "NAME", transformerNames.get(i)))
								{
								logMessage("Process " + process_class + "/" + process_type + "/" + process_name + " refers to transformer " + transformerNames.get(i) + " that doesn't exist", MISManager.PRIORITY_WARNING);
								recordProblemFound(process_class + "/" + process_type + "/" + process_name, "Missing transformer - " + transformerNames.get(i));
								}						
							}
						
						ArrayList scriptNames = XMLUtils.evaluatePathAsValueList(xml_doc, "/modules/module/class[text()=\"com.picdar.process2.Processing.ScriptProcessor.ScriptProcessor\"]/../config/script-name");
						ArrayList moreScriptNames = XMLUtils.evaluatePathAsValueList(xml_doc, "//modules/module/class[text()=\"com.picdar.process2.Processing.ScriptProcessor.CustomScriptSkeleton\"]/../config/script-name");
						scriptNames.addAll(moreScriptNames);
						for (int i = 0; i < scriptNames.size(); ++i)
							{
							if (!does_object_exist("SCRIPTS", "NAME", scriptNames.get(i)))
								{
								logMessage("Process " + process_class + "/" + process_type + "/" + process_name + " refers to script " + scriptNames.get(i) + " that doesn't exist", MISManager.PRIORITY_WARNING);
								recordProblemFound(process_class + "/" + process_type + "/" + process_name, "Missing script - " + scriptNames.get(i));
								}						
							}
				
						// check each module class referenced is valid
						ArrayList classNames = XMLUtils.evaluatePathAsValueList(xml_doc, "//modules/module/class");						
						for (int i = 0; i < classNames.size(); ++i)
							{
							try
								{
								String xx = classNames.get(i).trim();
								Class a_class = Class.forName(xx);
								}
							catch (Exception e)
								{
								logMessage("Process " + process_class + "/" + process_type + "/" + process_name + " refers to module " + classNames.get(i) + " that doesn't exist:" + e.getMessage(), MISManager.PRIORITY_WARNING);
								recordProblemFound(process_class + "/" + process_type + "/" + process_name, "Incorrect module class - " + classNames.get(i));
								}
							}
						}
					
					}					
				}
			}
		catch (SQLException | ResourceException e)
			{
			logMessage("Failed to perform process checks" + e.getMessage() , MISManager.PRIORITY_ERROR);
			}
		finally
			{
			try
				{
				if (rs != null)
					rs.close();
				if (statement != null)
					statement.close();
				if (pooledConn != null)
					pooledConn.release();
				}
			catch (Exception e)
				{
				logMessage("Failed to tidy up after previous error:" + e.getMessage() , MISManager.PRIORITY_ERROR);
				}
			}		
		}

        protected void doGroovyScriptChecks() {
            logMessage("Running groovy script checks..." , MISManager.PRIORITY_INFO);
            setProcessMessage("Running groovy script checks....");

            ScriptManager sm = (ScriptManager) ResourceManager.getInstance().getResource(ScriptManager.RESOURCE_NAME);
            ArrayList listOfScripts = sm.getScripts();

            for (String eachScript : listOfScripts) {
                logMessage("Checking script " + eachScript, MISManager.PRIORITY_DEBUG);
                try {
                    String scriptText = sm.getScript(eachScript, false);
                    GroovyClassLoader loader = new GroovyClassLoader(getClass().getClassLoader());
                    Class groovyClass = loader.parseClass(scriptText);

                } catch (Exception e) {
                    logMessage("Failed while validating groovy script " + eachScript, MISManager.PRIORITY_WARNING);
                    logMessage("Exception on script " + eachScript + ":" + e.getMessage(), MISManager.PRIORITY_DEBUG);
                    recordProblemFound(eachScript, "Script does not compile against this version of CHP");
                }
            }
        }
	
	protected void doLockChecks()
		{
		logMessage("Running lock checks..." , MISManager.PRIORITY_INFO);
		setProcessMessage("Running lock checks....");
		
		// just check if there are any especially old locks (> 1 day)
		JDBCPooledConnection pooledConn = null;
		Statement statement = null;
		ResultSet rs = null;
		try
			{
			pooledConn = DatabaseUtils.getJDBCConnectionForPool("JDBC");
			statement = pooledConn.createStatement();
			String sql = "SELECT COUNT(1) FROM MM_LOCK WHERE " +
				VendorSpecificJDBC.getSQLCurrDateFunc(pooledConn.getConnection()) +
				" > " +
				VendorSpecificJDBC.getSQLDateByInterval(pooledConn.getConnection(), "DATE_CREATED", "-", "DAY", "1");
			
			// count the folders so we can show progress
			rs = statement.executeQuery(sql);
			rs.next();
			int lockCount = rs.getInt(1);
			rs.close();		
			
			if (lockCount > 0)
				{
				logMessage("Found " + lockCount + " locks older than 24 hours" , MISManager.PRIORITY_WARNING);
				recordProblemFound("MM_LOCK", lockCount + " locks older than 24 hours found");				
				}
			}
		catch (SQLException | ResourceException e)
			{
			logMessage("Failed to perform lock checks" + e.getMessage() , MISManager.PRIORITY_ERROR);
			}
		finally
			{
			try
				{
				if (rs != null)
					rs.close();
				if (statement != null)
					statement.close();
				if (pooledConn != null)
					pooledConn.release();
				}
			catch (Exception e)
				{
				logMessage("Failed to tidy up after previous error:" + e.getMessage() , MISManager.PRIORITY_ERROR);
				}
			}		
		}
	
	protected void doTransformerChecks()
		{
		logMessage("Running transformer checks..." , MISManager.PRIORITY_INFO);
		setProcessMessage("Running transformer checks....");

		// validate each stylesheets
		StylesheetManager ssm = (StylesheetManager) ResourceManager.getInstance().getResource(StylesheetManager.RESOURCE_NAME);
		XMLManager xmlm = (XMLManager) ResourceManager.getInstance().getResource(XMLManager.RESOURCE_NAME);
		DataObjectArray all_transforms = ssm.getStylesheetList();

		int num_failed = 0;		
		for (int i = 0; i < all_transforms.size(); ++i)
			{
			DataObject a_transform = all_transforms.get(i);
	
			// run a transform against a trivial document to see if it validates
			// the document has a basic XMLDataObject structure...this is so that FOP transforms don't end up with no content inside their fo:root element
			String test_xml = "<?xml version=\"1.0\"?>";
			test_xml += "<XMLData>";
			test_xml += "<XMLDataObjects>";
			test_xml += "<XMLDataObject>";
			test_xml += "<primary_key type=\"PICTURE\" />";
			test_xml += "</XMLDataObject>";
			test_xml += "</XMLDataObjects>";
			test_xml += "</XMLData>";
			try
				{
				xmlm.transform(test_xml, a_transform.getAttributeAsString("NAME"));
				}
			catch (Exception e)
				{
				logMessage("Failed while validating stylesheet " + a_transform.getAttributeAsString("NAME"), MISManager.PRIORITY_WARNING);
				recordProblemFound(a_transform.getAttributeAsString("NAME"), "Invalid transformation");
				++num_failed;
				}
			}

		logMessage("Checked " + all_transforms.size() + " transformers, and found " + num_failed + " problems", MISManager.PRIORITY_INFO);
		}
	
	protected void doWorkflowChecks()
		{
		logMessage("Running workflow checks..." , MISManager.PRIORITY_INFO);
		setProcessMessage("Running workflow checks....");

		// check configs used by workflows are valid (these are XML definitions)
		HashMap<String,String> all_configs = new HashMap<String, String>();
		logMessage("Checking workflow configurations..." , MISManager.PRIORITY_INFO);
		JDBCPooledConnection pooledConn = null;
		Statement statement = null;
		ResultSet rs = null;
		try
			{
			pooledConn = DatabaseUtils.getJDBCConnectionForPool("JDBC");
			statement = pooledConn.createStatement();
            // Check the old and new workflow script tables in case the Database Model Checker is running in compability mode.
			String sql = "SELECT SCRIPT_ID, SCRIPT_NAME, SCRIPT_XML FROM (" +
                    "SELECT SCRIPT_ID,SCRIPT_NAME,TO_CHAR(SCRIPT_XML) AS SCRIPT_XML FROM WORKFLOW_CONFIG_XML" +
                    " UNION" +
                    " SELECT NODE_ID,KEY,TO_CHAR(SCRIPT_XML) AS SCRIPT_XML FROM WORKFLOW_SCRIPTS)";

			rs = statement.executeQuery(sql);
			while (rs.next())
				{
				String config_id = rs.getString(1);
				String script_name = rs.getString(2);
				String script_content = rs.getString(3);
				all_configs.put(config_id, config_id);
				
				if (!XMLUtils.isWellformedXML(script_content) && !script_name.equals("Dummy"))
					{
					logMessage("Invalid XML for workflow configuration " + script_name, MISManager.PRIORITY_WARNING);
					recordProblemFound("Workflow config/" + script_name, "Invalid XML");
					}
				}
			}
		catch (SQLException | ResourceException e)
			{
			logMessage("Failed to perform workflow job checks" + e.getMessage() , MISManager.PRIORITY_ERROR);
			}
		finally
			{
			try
				{
				if (rs != null)
					rs.close();
				if (statement != null)
					statement.close();
				if (pooledConn != null)
					pooledConn.release();
				}
			catch (Exception e)
				{
				logMessage("Failed to tidy up after previous error:" + e.getMessage() , MISManager.PRIORITY_ERROR);
				}
			}

		// workflow hierarchy checking - do basic checks first
		doFolderChecks("WORKFLOW_HIERARCHY", null, "WORKFLOW_HIERARCHY", true, true);
		
		// now also check other data in the workflow hierarchy
		HashMap<String,String> all_nodes = new HashMap<String, String>();
		logMessage("Checking workflow hierarchy (full check)..." , MISManager.PRIORITY_INFO);
		try
			{
			pooledConn = DatabaseUtils.getJDBCConnectionForPool("JDBC");
			statement = pooledConn.createStatement();
			String sql = "SELECT NODE_ID,ACTION_ON_STATE_CHANGE_TO,ACTION_ON_STATE_CHANGE_FROM FROM WORKFLOW_HIERARCHY";
			rs = statement.executeQuery(sql);
			while (rs.next())
				{
				String node_id = rs.getString(1);
				String action_to_id = rs.getString(2);
				String action_from_id = rs.getString(3);
				all_nodes.put(node_id, node_id);
				
				if (action_to_id != null && !action_to_id.equals("") && !action_to_id.equals("None") && all_configs.get(action_to_id) == null)
					{
					logMessage("Workflow node with ID " + node_id + " has an invalid ACTION_ON_STATE_CHANGE_TO of " + action_to_id, MISManager.PRIORITY_WARNING);
					recordProblemFound(node_id, "Workflow has invalid ACTION_ON_STATE_CHANGE_TO - " + action_to_id);
					}

				if (action_from_id != null && !action_from_id.equals("") && !action_to_id.equals("None") && all_configs.get(action_from_id) == null)
					{
					logMessage("Workflow node with ID " + node_id + " has an invalid ACTION_ON_STATE_CHANGE_FROM of " + action_from_id, MISManager.PRIORITY_WARNING);
					recordProblemFound(node_id, "Workflow has invalid ACTION_ON_STATE_CHANGE_FROM - " + action_from_id);
					}
				}
			}
		catch (SQLException | ResourceException e)
			{
			logMessage("Failed to perform workflow job checks" + e.getMessage() , MISManager.PRIORITY_ERROR);
			}
		finally
			{
			try
				{
				if (rs != null)
					rs.close();
				if (statement != null)
					statement.close();
				if (pooledConn != null)
					pooledConn.release();
				}
			catch (Exception e)
				{
				logMessage("Failed to tidy up after previous error:" + e.getMessage() , MISManager.PRIORITY_ERROR);
				}
			}

		// check workflow jobs are linked into hierarchy correctly (valid state)
		logMessage("Checking workflow jobs..." , MISManager.PRIORITY_INFO);
		try
			{
			pooledConn = DatabaseUtils.getJDBCConnectionForPool("JDBC");
			statement = pooledConn.createStatement();
			String sql = "SELECT WORKFLOW_ITEM_ID,STATE_ID,PACKAGE_ID,CREATOR,ASSIGNEE FROM WORKFLOW_ITEM";
			rs = statement.executeQuery(sql);
			while (rs.next())
				{
				String wf_item_id = rs.getString(1);
				String state_id = rs.getString(2);
				String package_id = rs.getString(3);
				String creator_id = rs.getString(4);
				String assignee_id = rs.getString(5);

				if (all_nodes.get(state_id) == null)
					{
					logMessage("Workflow job with ID " + wf_item_id + " has an invalid STATE_ID of " + state_id, MISManager.PRIORITY_WARNING);
					recordProblemFound(wf_item_id, "Workflow job has invalid STATE_ID - " + state_id);
					}
				
				if (package_id != null && !package_id.equals(""))
					{
					if (!does_object_exist("PACKAGES", "NODE_ID", package_id))
						{
						logMessage("Workflow job with ID " + wf_item_id + " is linked to PACKAGE_ID " + package_id + " that doesn't exist", MISManager.PRIORITY_WARNING);
						recordProblemFound(wf_item_id, "Workflow job has invalid PACKAGE_ID - " + package_id);						
						}
					}
					
				if (itsUserGroupIDs.contains(creator_id))
					{
					// then creator ID is OK
					}
				else if (itsUserAccountIDs.contains(creator_id))
					{
					// then creator ID is OK
					}
				else
					{
					logMessage("Failed to match creator " + creator_id + " of workflow jobs " + wf_item_id + " to any valid user group or user account." , MISManager.PRIORITY_WARNING);
					recordProblemFound(wf_item_id, "Creator " + creator_id + " is invalid");
					}

				if (itsUserGroupIDs.contains(assignee_id))
					{
					// then assignee ID is OK
					}
				else if (itsUserAccountIDs.contains(assignee_id))
					{
					// then assignee ID is OK
					}
				else
					{
					logMessage("Failed to match assignee " + assignee_id + " of workflow jobs " + wf_item_id + " to any valid user group or user account." , MISManager.PRIORITY_WARNING);
					recordProblemFound(wf_item_id, "Assignee " + assignee_id + " is invalid");
					}
					
				// check assets linked to jobs exist
				Statement statement2 = null;
				ResultSet rs2 = null;
				try
					{
					statement2 = pooledConn.createStatement();
					String sql2 = "SELECT ASSET_ID FROM WORKFLOW_ITEM_ASSET WHERE WORKFLOW_ITEM_ID='" + wf_item_id + "'";
					rs2 = statement2.executeQuery(sql2);
					while (rs2.next())
						{
						String wf_asset_id = rs2.getString(1);
						if (!does_object_exist("ASSET", "ASSET_ID", wf_asset_id) && !does_object_exist("EDITION_INSTANCE", "EDITION_INSTANCE_ID", wf_asset_id))
							{
							logMessage("Workflow job with ID " + wf_item_id + " container asset " + wf_asset_id + " that doesn't exist", MISManager.PRIORITY_WARNING);
							recordProblemFound(wf_item_id, "Workflow job has missing ASSET - " + wf_asset_id);						
							}
						}
					}
				catch (SQLException | ResourceException e)
					{
					logMessage("Failed to perform workflow job checks" + e.getMessage() , MISManager.PRIORITY_ERROR);
					}
				finally
					{
					try
						{
						if (rs2 != null)
							rs2.close();
						if (statement2 != null)
							statement2.close();
						}
					catch (Exception e)
						{
						logMessage("Failed to tidy up after previous error:" + e.getMessage() , MISManager.PRIORITY_ERROR);
						}
					}


				}
			}
		catch (SQLException | ResourceException e)
			{
			logMessage("Failed to perform workflow job checks" + e.getMessage() , MISManager.PRIORITY_ERROR);
			}
		finally
			{
			try
				{
				if (rs != null)
					rs.close();
				if (statement != null)
					statement.close();
				if (pooledConn != null)
					pooledConn.release();
				}
			catch (Exception e)
				{
				logMessage("Failed to tidy up after previous error:" + e.getMessage() , MISManager.PRIORITY_ERROR);
				}
			}				
		}
	
	protected void doEMDChecks()
		{
		logMessage("Running EMD checks..." , MISManager.PRIORITY_INFO);
		setProcessMessage("Running EMD checks....");
		doFolderChecks("SPECIALISTMD_HIERARCHY", null, "SPECIALISTMD_HIERARCHY", false, true);
		}	
	
	protected boolean isValidJSONArray(String jsonStr)
		{
		boolean is_valid_json = false;
		try
			{
			JSONArray jo = new JSONArray(jsonStr);
			is_valid_json = true;
			}
		catch (Exception e)
			{
			is_valid_json = false;
			}
		return is_valid_json;
		}

	protected boolean isValidJSONObject(String jsonStr)
		{
		boolean is_valid_json = false;
		try
			{
			JSONObject jo = new JSONObject(jsonStr);
			is_valid_json = true;
			}
		catch (Exception e)
			{
			is_valid_json = false;
			}
		return is_valid_json;
		}
	
	protected void checkTemplate(String tableName)
		{
		//Check content of each template is valid
		logMessage("Running " + tableName + " template checks..." , MISManager.PRIORITY_INFO);
		
		JDBCPooledConnection pooledConn = null;
		Statement statement = null;
		ResultSet rs = null;
		try
			{
			pooledConn = DatabaseUtils.getJDBCConnectionForPool("JDBC");
			statement = pooledConn.createStatement();
			String sql = "SELECT TEMPLATE_ID,NAME,OWNER_ID";
			if (tableName.equalsIgnoreCase("ASSET_TEMPLATES")
				|| tableName.equalsIgnoreCase("RESULTS_TEMPLATES")
				|| tableName.equalsIgnoreCase("ARTICLE_TEMPLATES")
				|| tableName.equalsIgnoreCase("DASHBOARD_TEMPLATES")
				|| tableName.equalsIgnoreCase("SEARCH_TEMPLATES")
				|| tableName.equalsIgnoreCase("DISCOVERY_TEMPLATES"))
				sql += ",CONTENT";
			else if (tableName.equalsIgnoreCase("PREF_TEMPLATES")
				|| tableName.equalsIgnoreCase("SYSMGT_PREF_TEMPLATES"))
				sql += ",PREFERENCES_CLOB";
			sql += " FROM " + tableName;

			rs = statement.executeQuery(sql);
			while (rs.next())
				{
				String template_id = rs.getString(1);
				String template_name = rs.getString(2);
				String owner_id = rs.getString(3);

				if (owner_id != null)
					checkObjectOwner(template_id, owner_id, template_name, tableName);
				else
					{
					logMessage("Owner is null for " + tableName + "/" + template_name, MISManager.PRIORITY_WARNING);
					recordProblemFound(tableName + "/" + template_name, "Owner is null");
					}
				checkObjectPolicies(template_id, template_name, tableName, null);
				
				if (tableName.equalsIgnoreCase("DASHBOARD_TEMPLATES")
					|| tableName.equalsIgnoreCase("DISCOVERY_TEMPLATES"))
					{
					String template_content = rs.getString(4);
					if (!isValidJSONArray(template_content))
						{
						logMessage("Invalid JSON for " + tableName + "/" + template_name, MISManager.PRIORITY_WARNING);
						recordProblemFound(tableName + "/" + template_name, "Invalid JSON");
						}
					}
				else if (tableName.equalsIgnoreCase("ASSET_TEMPLATES")
					|| tableName.equalsIgnoreCase("SEARCH_TEMPLATES")
					|| tableName.equalsIgnoreCase("ARTICLE_TEMPLATES")
					|| tableName.equalsIgnoreCase("RESULTS_TEMPLATES"))
					{
					String template_content = rs.getString(4);
					if (!isValidJSONObject(template_content))
						{
						logMessage("Invalid JSON for " + tableName + "/" + template_name, MISManager.PRIORITY_WARNING);
						recordProblemFound(tableName + "/" + template_name, "Invalid JSON");
						}
					}
				else
					{
					String template_content = rs.getString(4);
					if (!XMLUtils.isWellformedXML(template_content))
						{
						logMessage("Invalid XML for " + tableName + "/" + template_name, MISManager.PRIORITY_WARNING);
						recordProblemFound(tableName + "/" + template_name, "Invalid XML");
						}
					}
				}
			}
		catch (SQLException | ResourceException e)
			{
			logMessage("Failed to perform lock checks" + e.getMessage() , MISManager.PRIORITY_ERROR);
			}
		finally
			{
			try
				{
				if (rs != null)
					rs.close();
				if (statement != null)
					statement.close();
				if (pooledConn != null)
					pooledConn.release();
				}
			catch (Exception e)
				{
				logMessage("Failed to tidy up after previous error:" + e.getMessage() , MISManager.PRIORITY_ERROR);
				}
			}
		}
	
	protected void doTemplateChecks()
		{
		logMessage("Running template checks..." , MISManager.PRIORITY_INFO);
		setProcessMessage("Running template checks....");
		
		checkTemplate("ASSET_TEMPLATES");
		checkTemplate("RESULTS_TEMPLATES");
		checkTemplate("DISCOVERY_TEMPLATES");
		checkTemplate("DASHBOARD_TEMPLATES");
		checkTemplate("ARTICLE_TEMPLATES");
		checkTemplate("PREF_TEMPLATES");
		checkTemplate("SYSMGT_PREF_TEMPLATES");
		checkTemplate("SEARCH_TEMPLATES");
		}

	protected HashMap<String, String> loadSecurityTable(String tableName, String idField, String fieldName)
		{
		JDBCPooledConnection pooledConn = null;
		Statement statement = null;
		ResultSet rs = null;

		HashMap<String, String> table_values = new HashMap<String, String>();
		try
			{
			pooledConn = DatabaseUtils.getJDBCConnectionForPool("JDBC");
			statement = pooledConn.createStatement();
			String sql = "SELECT " + idField + "," + fieldName + " FROM " + tableName;

			rs = statement.executeQuery(sql);
			while (rs.next())
				{
				String id_value = rs.getString(1);
				String name_value = rs.getString(2);
				table_values.put(id_value, name_value);
				}
			}
		catch (SQLException | ResourceException e)
			{
			logMessage("Failed to load contents of security table" + e.getMessage() , MISManager.PRIORITY_ERROR);
			}
		finally
			{
			try
				{
				if (rs != null)
					rs.close();
				if (statement != null)
					statement.close();
				if (pooledConn != null)
					pooledConn.release();
				}
			catch (Exception e)
				{
				logMessage("Failed to tidy up after previous error:" + e.getMessage() , MISManager.PRIORITY_ERROR);
				}
			}
		return table_values;		
		}
	
	void doSecurityChecks()
		{
		logMessage("Running security checks..." , MISManager.PRIORITY_INFO);
		setProcessMessage("Running security checks....");
		
		// load contents of a set of tables ready to use for lookups
		HashMap<String, String> all_privs = loadSecurityTable("MM_PRIVILEGE", "PRIVILEGE_ID", "PRIVILEGE_NAME");
		HashMap<String, String> all_user_groups = loadSecurityTable("MM_ROLE", "ROLE_ID", "ROLE_NAME");
		HashMap<String, String> all_priv_groups = loadSecurityTable("MM_PRIV_GROUP", "GROUP_ID", "NAME");

		// check privilege group definitions in GROUP_PRIV_LINK...do each of the privs referenced exist in MM_PRIVILEGE?
		JDBCPooledConnection pooledConn = null;
		Statement statement = null;
		ResultSet rs = null;
		try
			{
			pooledConn = DatabaseUtils.getJDBCConnectionForPool("JDBC");
			statement = pooledConn.createStatement();
			String sql = "SELECT GROUP_ID,PRIVILEGE_ID FROM GROUP_PRIV_LINK";

			rs = statement.executeQuery(sql);
			while (rs.next())
				{
				String priv_group_id = rs.getString(1);
				String priv_id = rs.getString(2);
				
				if (all_priv_groups.get(priv_group_id) == null)
					{
					logMessage("Entry in GROUP_PRIV_LINK is missing GROUP_ID " + priv_group_id + " IN MM_PRIV_GROUP table", MISManager.PRIORITY_WARNING);
					recordProblemFound("GROUP_PRIV_LINK/" + priv_group_id, "Invalid group entry");
					}
				
				if (all_privs.get(priv_id) == null)
					{
					logMessage("Entry in GROUP_PRIV_LINK is missing PRIVILEGE_ID " + priv_id + " IN MM_PRIVILEGE table", MISManager.PRIORITY_WARNING);
					recordProblemFound("GROUP_PRIV_LINK/" + priv_id, "Invalid privilege entry");
					}
				}
			}
		catch (SQLException | ResourceException e)
			{
			logMessage("Failed to perform privilege group checks" + e.getMessage() , MISManager.PRIORITY_ERROR);
			}
		finally
			{
			try
				{
				if (rs != null)
					rs.close();
				if (statement != null)
					statement.close();
				if (pooledConn != null)
					pooledConn.release();
				}
			catch (Exception e)
				{
				logMessage("Failed to tidy up after previous error:" + e.getMessage() , MISManager.PRIORITY_ERROR);
				}
			}
		
		// check profile templates - entries in MM_APP_PROFILE that have the template flag set
		// for each profile template, check that:
		// "PROFILE_ROLE_LINK" (or PROFILE_GROUP_LINK?) contains valid entries for profile template to user groups 
		// "PROFILE_PRIV_LINK" contains valid entries for profile template to user privileges
		try
			{
			pooledConn = DatabaseUtils.getJDBCConnectionForPool("JDBC");
			statement = pooledConn.createStatement();
			String sql = "SELECT PROFILE_ID,NAME FROM MM_APP_PROFILE WHERE PROFILE_TEMPLATE='1'";

			rs = statement.executeQuery(sql);
			while (rs.next())
				{
				String profile_id = rs.getString(1);
				String profile_name = rs.getString(2);
				
				Statement statement2 = null;
				ResultSet rs2 = null;
				try
					{
					boolean found_default = false;
					int link_count = 0;
					statement2 = pooledConn.createStatement();
					String sql2 = "SELECT ROLE_ID,DEFAULT_ROLE,LINK_ID FROM PROFILE_ROLE_LINK WHERE PROFILE_ID='" + profile_id + "'";		
					rs2 = statement2.executeQuery(sql2);
					while (rs2.next())
						{
						String role_id = rs2.getString(1);
						String is_default = rs2.getString(2);
						String link_id = rs2.getString(3);
						
						if (all_user_groups.get(role_id) == null)
							{
							logMessage("Profile template with name " + profile_name + " is linked to missing user group " + role_id, MISManager.PRIORITY_WARNING);
							recordProblemFound(profile_name, "Linked to user group " + role_id + " that doesn't exist");						
							}
						
						if (PicdarBoolean.booleanValue(is_default))
							found_default = true;
							
						// check link from the profile-group-link to the entity priv group for this user group
						Statement statement3 = null;
						ResultSet rs3 = null;
						try
							{
							statement3 = pooledConn.createStatement();
							String sql3= "SELECT GROUP_ID FROM PGL_GROUP_LINK WHERE PGL_ID=" + link_id;
							rs3 = statement3.executeQuery(sql3);
							while (rs3.next())
								{
								String group_id = rs3.getString(1);
								
								if (all_priv_groups.get(group_id) == null)
									{
									logMessage("Profile template with name " + profile_name + " is linked to user group " + role_id + ", but has missing entity priv group with ID " + group_id, MISManager.PRIORITY_WARNING);
									recordProblemFound(profile_name, "Invalid privilege group " + group_id + " for user group with ID " + group_id);						
									}								
								}
							}
						catch (SQLException | ResourceException e)
							{
							logMessage("Failed to perform profile template group checks" + e.getMessage() , MISManager.PRIORITY_ERROR);
							}
						finally
							{
							try
								{
								if (rs3 != null)
									rs3.close();
								if (statement3 != null)
									statement3.close();
								}
							catch (Exception e)
								{
								logMessage("Failed to tidy up after previous error:" + e.getMessage() , MISManager.PRIORITY_ERROR);
								}
							}
							
						++link_count;
						}
					if (link_count > 0 && !found_default)
						{
						logMessage("Failed to find default user group for profile template with name " + profile_name + " but it maybe ok if there are no entity privileges", MISManager.PRIORITY_WARNING);
						recordProblemFound(profile_name, "No default user group set for profile template but maybe ok if there are no entity privileges");
						}						
					}
				catch (SQLException | ResourceException e)
					{
					logMessage("Failed to perform profile template group checks" + e.getMessage() , MISManager.PRIORITY_ERROR);
					}
				finally
					{
					try
						{
						if (rs2 != null)
							rs2.close();
						if (statement2 != null)
							statement2.close();
						}
					catch (Exception e)
						{
						logMessage("Failed to tidy up after previous error:" + e.getMessage() , MISManager.PRIORITY_ERROR);
						}
					}
					
				// check PROFILE_GROUP_LINK for user privilege feature groups
				try
					{
					statement2 = pooledConn.createStatement();
					String sql2 = "SELECT GROUP_ID FROM PROFILE_GROUP_LINK WHERE PROFILE_ID='" + profile_id + "'";		
					rs2 = statement2.executeQuery(sql2);
					while (rs2.next())
						{
						String priv_group_id = rs2.getString(1);
						
						if (all_priv_groups.get(priv_group_id) == null)
							{
							logMessage("Profile template with name " + profile_name + " is linked to missing feature priv group " + priv_group_id, MISManager.PRIORITY_WARNING);
							recordProblemFound("MM_APP_PROFILE/" + profile_id, "Invalid feature priv group " + priv_group_id);
							}
						}
					}
				catch (SQLException | ResourceException e)
					{
					logMessage("Failed to perform profile template group checks" + e.getMessage() , MISManager.PRIORITY_ERROR);
					}
				finally
					{
					try
						{
						if (rs2 != null)
							rs2.close();
						if (statement2 != null)
							statement2.close();
						}
					catch (Exception e)
						{
						logMessage("Failed to tidy up after previous error:" + e.getMessage() , MISManager.PRIORITY_ERROR);
						}
					}
				}
			}
		catch (SQLException | ResourceException e)
			{
			logMessage("Failed to perform privilege group checks" + e.getMessage() , MISManager.PRIORITY_ERROR);
			}
		finally
			{
			try
				{
				if (rs != null)
					rs.close();
				if (statement != null)
					statement.close();
				if (pooledConn != null)
					pooledConn.release();
				}
			catch (Exception e)
				{
				logMessage("Failed to tidy up after previous error:" + e.getMessage() , MISManager.PRIORITY_ERROR);
				}
			}		
		}
	
	protected void clearReportQueue()
		{
		String queue_name = getConfigValue(PARAM_QUEUE_NAME);

		logMessage("Emptying report queue (" + queue_name + ")..." , MISManager.PRIORITY_INFO);		
		
		// just check if there are any especially old locks (> 1 day)
		JDBCPooledConnection pooledConn = null;
		Statement statement = null;
		try
			{
			pooledConn = DatabaseUtils.getJDBCConnectionForPool("JDBC");
			statement = pooledConn.createStatement();
			String sql = "DELETE FROM MM_QUEUE WHERE QUEUE_NAME='" + queue_name + "'";
			statement.executeUpdate(sql);
			}
		catch (SQLException | ResourceException e)
			{
			logMessage("Failed to clear report queue" + e.getMessage() , MISManager.PRIORITY_ERROR);
			}
		finally
			{
			try
				{
				if (statement != null)
					statement.close();
				if (pooledConn != null)
					pooledConn.release();
				}
			catch (Exception e)
				{
				logMessage("Failed to tidy up after previous error:" + e.getMessage() , MISManager.PRIORITY_ERROR);
				}
			}		
		}

        public void checkStoryAntiSamyValidation(String assetId) {

            String stringToScan = null;
            String segments = null;
            DataManager dataMan = (DataManager) ResourceManager.getInstance().getResource(DataManager.RESOURCE_NAME);
            DataObject storyObj = dataMan.getDataObject(new PrimaryKey(assetId));
            int nodeCount = 0;
            // logMessage("storyObj: " + storyObj, MISManager.PRIORITY_DEBUG);

            if (storyObj != null) {

                segments = storyObj.getAttributeAsString("SEGMENTS");
                logMessage("Asset ID: " + assetId + ";Segments: " + segments, MISManager.PRIORITY_DEBUG);
                // String segmentsToXML = XMLUtils.decodeXML(segments);
                if (segments != null && !segments.equals("")) {
                    // Firstly get the count of number of segments
                    nodeCount = XMLUtils.evaluatePathAsNodeCount(segments, "/story-segments/segment/content");

                    // logMessage("Performing Antisamy checks for story " + assetId, MISManager.PRIORITY_INFO);
                    int i = 1;

                    // Iterate over each of the content segments and check them
                    while (i <= nodeCount) {
                        stringToScan = XMLUtils.evaluatePathAsValue(segments, "/story-segments/segment[" + i + "]/content");
                        logMessage("value to check: " + stringToScan, MISManager.PRIORITY_DEBUG);
                        if (stringToScan != null) {

                            String configFile = ResourceManager.getInstance().getItsBaseFilePath() + "/WEB-INF/Resources/antisamy-chp.xml";

                            Pattern STYLE_ELIMINATOR = Pattern.compile("style=\".*?\"");
                            Pattern WHITESPACE_ELIMINATOR = Pattern.compile("[\\r\\n\\s]");
                            Pattern XML_DECLARATION_ELIMINATOR = Pattern.compile("<\\?xml .*?>");
                            Pattern URL_QUOTE_ELIMINATOR = Pattern.compile("(url\\()&quot;(.*?)&quot;(\\))");

                            org.owasp.validator.html.Policy policy = org.owasp.validator.html.Policy.getInstance(new File(configFile));
                            AntiSamy itsAntiSamy = new AntiSamy(policy);

                            // code to get the XML for a story…assume this is in “stringToScan” variable
                            // we do a set of “clean up” actions to prepare the XML
                            stringToScan = stringToScan.replaceAll("\\s/>", "/>");
                            stringToScan = stringToScan.replaceAll("<br>", "<br/>");
                            stringToScan = stringToScan.replaceAll("\\\\\"", "\"");
                            stringToScan = stringToScan.replaceAll("&apos;", "'");

                            stringToScan = STYLE_ELIMINATOR.matcher(stringToScan).replaceAll("");

                            CleanResults cleanResults = itsAntiSamy.scan(stringToScan); // Scan parameter value
                            // String cleanHtml = StringEscapeUtils.unescapeHtml4(cleanResults.getCleanHTML().trim());
                            String cleanHtml = ESAPI.encoder().decodeForHTML(cleanResults.getCleanHTML().trim());
                            int noOfErr = cleanResults.getNumberOfErrors();
                            List errMssgs = cleanResults.getErrorMessages();

                            if (noOfErr > 0) {
                                // Then AntiSamy found a problem so deal with it…
                                logMessage("Found " + noOfErr + " error(s) with the XML " + stringToScan + " for asset " + assetId, MISManager.PRIORITY_ERROR);
                                logMessage("Error message(s): " + errMssgs.toArray(), MISManager.PRIORITY_ERROR);
                                recordProblemFound(assetId, "Failed AntiSamy Checks - " + errMssgs.toArray());
                            } else {
                                // do another check that what AntiSamy cleaned up matches the original content
                                String trimmedOriginal = XML_DECLARATION_ELIMINATOR.matcher(stringToScan).replaceAll("");
                                trimmedOriginal = URL_QUOTE_ELIMINATOR.matcher(trimmedOriginal).replaceAll("\$1\$2\$3");
                                trimmedOriginal = WHITESPACE_ELIMINATOR.matcher(trimmedOriginal).replaceAll("");
                                // trimmedOriginal = StringEscapeUtils.unescapeHtml4(trimmedOriginal);
                                trimmedOriginal = ESAPI.encoder().decodeForHTML(trimmedOriginal);

                                String trimmedCleanValue = WHITESPACE_ELIMINATOR.matcher(cleanHtml).replaceAll("");
                                if (!trimmedOriginal.equalsIgnoreCase(trimmedCleanValue)) {
                                    // Then there was a problem because the cleaned value didn’t match the original, so there might have been some “injection”
                                    logMessage("Found an error with the XML after trimming clean value", MISManager.PRIORITY_ERROR);
                                    logMessage("trimmedOriginal: " + trimmedOriginal, MISManager.PRIORITY_DEBUG);
                                    logMessage("trimmedCleanValue: " + trimmedCleanValue, MISManager.PRIORITY_DEBUG);
                                    recordProblemFound(assetId, "Failed XML Trim Clean");
                                } else {
                                    logMessage("No errors found", MISManager.PRIORITY_DEBUG);
                                }
                            }
                        }
                        i++;
                    }
                }
            }
        }
        /*
        public Date addMinutesToJavaUtilDate(java.sql.Date date, int minutes) {

            // Timestamp now = new java.util.Date(date.getTime());
            Calendar calendar = Calendar.getInstance();
            calendar.setTime(now.getTime());
            calendar.add(Calendar.MINUTE, minutes);
            Timestamp later = new Timestamp(calendar.getTime().getTime());
            return calendar.getTime().getTime();
        }
        */
	
	public int iterationExecute(ProcessModuleData processData)
		{
		logMessage("Starting database model checker..." , MISManager.PRIORITY_INFO);
		
		loadCacheLookups();
		
		String clear_queue = getConfigValue(PARAM_CLEAR_QUEUE);
		if (PicdarBoolean.booleanValue(clear_queue))
			clearReportQueue();

		String checksToDo = getConfigValue(PARAM_CHECKS);
		if (checksToDo == null || checksToDo.equals(""))
			logMessage("No checks have been configured - set the checks-to-perform script property", MISManager.PRIORITY_INFO);
		else
			{
			// all deliberately doesn't include index-against-database
			if (checksToDo.equalsIgnoreCase("all"))
				 checksToDo = "assets,index-sanity-checks,users,publications,lists,processes,locks,transformers,workflow,emd,templates,personal_folders,community_folders,feeds,packages,parking";
			else if (checksToDo.equalsIgnoreCase("all-except-assets"))
				 checksToDo = "users,publications,lists,processes,locks,transformers,workflow,emd,templates,personal_folders,community_folders,feeds,packages,parking";
			
			StringTokenizer checks = new StringTokenizer(checksToDo, ",");
			while (checks.hasMoreTokens())
				{
				String aCheck = checks.nextToken();
				aCheck = aCheck.trim();
				
				if (aCheck.equalsIgnoreCase("assets"))
					doAssetChecks();
				else if (aCheck.equalsIgnoreCase("index-against-database"))
					doIndexChecks();
				else if (aCheck.equalsIgnoreCase("index-sanity-checks"))
					doIndexSanityChecks();
				else if (aCheck.equalsIgnoreCase("users"))
					doUserChecks();
				else if (aCheck.equalsIgnoreCase("publications"))
					doPublicationChecks();
				else if (aCheck.equalsIgnoreCase("lists"))
					doListChecks();
				else if (aCheck.equalsIgnoreCase("processes"))
					doProcessChecks();
                else if (aCheck.equalsIgnoreCase("groovy-scripts"))
                    doGroovyScriptChecks();
				else if (aCheck.equalsIgnoreCase("locks"))
					doLockChecks();
				else if (aCheck.equalsIgnoreCase("transformers"))
					doTransformerChecks();
				else if (aCheck.equalsIgnoreCase("workflow"))
					doWorkflowChecks();
				else if (aCheck.equalsIgnoreCase("emd"))
					doEMDChecks();
				else if (aCheck.equalsIgnoreCase("security"))
					doSecurityChecks();
				else if (aCheck.equalsIgnoreCase("templates"))
					doTemplateChecks();
				else if (aCheck.equalsIgnoreCase("personal_folders"))
					doFolderChecks( "MM_SHELF", "MM_ASSET_SHELF", "personal folder", true, true);
				else if (aCheck.equalsIgnoreCase("community_folders"))
					doFolderChecks("HARD_CATEGORIES", "ASSET_CATEGORY", "community folder", true, true);
				else if (aCheck.equalsIgnoreCase("feeds"))
					doFolderChecks("FEEDS", null, "feed", true, true);
				else if (aCheck.equalsIgnoreCase("packages"))
					doFolderChecks("PACKAGES", "ASSET_PACKAGES", "package", true, true);
				else if (aCheck.equalsIgnoreCase("parking"))
					doFolderChecks("MM_PARKING", "PARKED_ASSET_LINK", "parking area", true, true);
				else
					logMessage(aCheck + " is not a valid check to perform", MISManager.PRIORITY_INFO);
				}
			}

		setFinished(true);
		return CONTINUE;
		}

        public boolean isAfterDateCheck(java.sql.Date initialDate, java.sql.Timestamp nowTimestamp) {

            java.util.Date creationUtilDate = new java.util.Date(initialDate.getTime());

            int futureDateOffsetInSecs = 300;

            if (getConfigValue(PARAM_OFFSET_FUTURE_DATE) != null)
                futureDateOffsetInSecs = Integer.valueOf(getConfigValue(PARAM_OFFSET_FUTURE_DATE));

            // Add an offset of 5 minutes in case the now timestamp is more than 5 minutes old.
            Calendar calendar = Calendar.getInstance();
            calendar.setTimeInMillis(nowTimestamp.getTime());
            calendar.add(Calendar.SECOND, futureDateOffsetInSecs);
            java.util.Date nowUtilDatePlusOneMin = calendar.getTime();

            logMessage("Initial Stamp: " + creationUtilDate + "; Time now (+5 min): " + nowUtilDatePlusOneMin, MISManager.PRIORITY_DEBUG);

            if(creationUtilDate.after(nowUtilDatePlusOneMin)) {
                return true;
            } else {
                return false;
            }
        }

	}
