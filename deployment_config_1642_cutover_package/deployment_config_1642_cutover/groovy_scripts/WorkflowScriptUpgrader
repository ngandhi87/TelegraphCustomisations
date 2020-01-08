import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.*;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

import com.picdar.common.DataSource.DataObject;
import com.picdar.common.DataSource.PrimaryKey;
import com.picdar.common.ObjectPool.ObjectPool;
import com.picdar.common.Utilities.StringFormat;
import com.picdar.common.XMLSupport.Utils.XMLUtils;
import com.picdar.eis.JDBC.ConnectionPool.JDBCPooledConnection;
import com.picdar.eis.JDBC.PrimaryKey.PrimaryKeyManager;
import com.picdar.eis.JDBC.VendorSpecific.VendorJDBC;
import com.picdar.eis.JDBC.VendorSpecific.VendorSpecificJDBC;
import com.picdar.process2.Core.ProcessItem;
import com.picdar.process2.Core.ProcessModuleData;
import com.picdar.process2.Processing.ScriptProcessor.ProcessModuleScript;
import com.picdar.resource.Core.ResourceManager;
import com.picdar.resource.DataManager.DataManager;
import com.picdar.resource.MISManager.MISManager;
import com.picdar.resource.PoolManager.PoolManager;
import com.picdar.resource.SecurityManager.JDBC.SecurityManagerSQL;

public class WorkflowScriptUpgrader extends ProcessModuleScript
	{
	public WorkflowScriptUpgrader()
		{
		}

	public WorkflowScriptUpgrader(HashMap props)
		{
		super(props);
		}

	@Override
	public void execute(ProcessItem itemToProcess, ProcessModuleData processData)
		{
		JDBCPooledConnection conn = null;
		
		try
			{
			PoolManager poolMan = (PoolManager) ResourceManager.getInstance().getResource(PoolManager.RESOURCE_NAME);
			ObjectPool pool = poolMan.getPool("JDBC");
			conn = (JDBCPooledConnection) pool.get("Getting a JDBC pool object for upgrading workflow scripts");

			// Find the scripts that need to be upgraded.
			Statement stat = null;
	        ResultSet rs = null;
	        List<String> scriptsToProcess = new ArrayList<String>();
	        
	        try
	        	{
				stat = conn.createStatement();
	            rs = stat.executeQuery("select a.node_id, a.key, a.script_type, count(b.node_id) from workflow_scripts a left join workflow_scripts b on a.node_id = b.parent_id where a.key_level = 0 group by a.node_id, a.key, a.script_type");
	            
	            while (rs.next())
	                {
	                String scriptID = rs.getString(1);
	                String scriptName = rs.getString(2);
	                String scriptType = rs.getString(3);
	                int numBlocks = rs.getInt(4);
	                
	                if (scriptType == null)
	                	logMessage("Ignoring script '" + scriptName + "' (id = '" + scriptID + "') as it doesn't have a type.", MISManager.PRIORITY_INFO);
	                else if (scriptType.toLowerCase().startsWith("file_to"))
	                	logMessage("Ignoring script '" + scriptName + "' (id = '" + scriptID + "') as it is a FILE TO script.", MISManager.PRIORITY_INFO);
	                else if (numBlocks != 1)
	                	logMessage("Ignoring script '" + scriptName + "' (id = '" + scriptID + "') as it doesn't contain a single script block.", MISManager.PRIORITY_INFO);
	                else
	                	scriptsToProcess.add(scriptID);
	                
	                // logMessage("Found script " + scriptName + " with " + numBlocks + " blocks.", MISManager.PRIORITY_INFO);
	                }
	        	}
	        finally
		        {
	            if (rs != null)
	                rs.close();
				if (stat != null)
					conn.closeStatement(stat);
		        }

	        logMessage("************************************", MISManager.PRIORITY_INFO);
	        logMessage("Starting upgrading of scripts...", MISManager.PRIORITY_INFO);
	        logMessage("************************************", MISManager.PRIORITY_INFO);
	        
	        List<String> fieldsFromScript = new ArrayList<String>();
	        fieldsFromScript.add("KEY");
	        fieldsFromScript.add("SCRIPT_TYPE");
	        fieldsFromScript.add("DESCRIPTION");
	        fieldsFromScript.add("SCRIPT_XML");
	        List<String> fieldsFromBlock = new ArrayList<String>();
	        fieldsFromBlock.add("SCRIPT_XML");
	        
            // Loop through each of the scripts to be upgraded.
	        for (String scriptToProcess : scriptsToProcess)
	        	{
	        	try
	        		{
		        	Map<String, String> scriptInfo = getOldScriptInfo(conn, scriptToProcess, true, fieldsFromScript);
		        	String scriptName = scriptInfo.get("KEY");
		        	String newScriptID = null;
		        	
		        	// Check that a new workflow_config_xml object doesn't already exist with the same name.
		        	Map<String, String> newScriptInfo = getNewScriptInfo(conn, scriptName);
		        	if (newScriptInfo != null)
		        		{
		        		newScriptID = newScriptInfo.get("SCRIPT_ID");
		        		logMessage("Skipping creation of script '" + scriptName + "' as it already exists (id = '" + newScriptID + "').", MISManager.PRIORITY_INFO);
		        		}
		        	else
		        		{
		        		// Script doesn't yet exist, so generate the new XML and create the script.
		        		Map<String, String> blockInfo = getOldScriptInfo(conn, scriptToProcess, false, fieldsFromBlock);
		        		
		        		newScriptID = createNewScript(conn, scriptInfo, blockInfo);
		        		logMessage("Created script '" + scriptName + "' (id = '" + newScriptID + "').", MISManager.PRIORITY_INFO);
		        		}
		        	
		        	// Update any links in the WORKFLOW_HIERARCHY to the new script.
		        	if (newScriptID != null)
		        		{
		        		// Look for any references to the old script ID (scriptToProcess) and update it with the new script ID (newScriptID).
		        		int refsChanged = 0;
		        		refsChanged += updateScriptReference(conn, "ACTION_ON_STATE_CHANGE_TO", scriptToProcess, newScriptID);
		        		refsChanged += updateScriptReference(conn, "ACTION_ON_STATE_CHANGE_FROM", scriptToProcess, newScriptID);
		        		refsChanged += updateScriptReference(conn, "VALIDATE_ON_STATE_CHANGE_FROM", scriptToProcess, newScriptID);
		        		refsChanged += updateScriptReference(conn, "VALIDATE_ON_STATE_CHANGE_TO", scriptToProcess, newScriptID);
		        		
		        		if (refsChanged > 0)
		        			{
		        			touchWorkflowHierarchyAudit(conn);
		        			logMessage("Updated " + refsChanged + " reference(s) for script '" + scriptName + "' (id = '" + newScriptID + "') in the WORKFLOW_HIERARCHY table.", MISManager.PRIORITY_INFO);
		        			}
		        		}
	        		}
	        	catch (Exception e)
	        		{
	        		logMessage("Error occurred while processing script '" + scriptToProcess + "'.", e, MISManager.PRIORITY_INFO);
	        		}
	        	}
			}
		catch (Exception e)
			{
			logMessage("Unexpected error while upgrading workflow scripts.", e, MISManager.PRIORITY_ERROR);
			}
		finally
			{
			if (conn != null)
				conn.release();
			}
		}
	
	protected Map<String, String> getOldScriptInfo(JDBCPooledConnection conn, String scriptID, boolean isScript, List<String> fields) throws Exception
		{
		Map<String, String> scriptInfo = null;
		
		Statement stat = null;
        ResultSet rs = null;
        
        try
        	{
        	StringBuilder sql = new StringBuilder();
        	sql.append("select ");
        	sql.append(StringFormat.join(fields, ", "));
        	sql.append(" from workflow_scripts where ");
        	if (isScript)
        		sql.append("NODE_ID");
        	else
        		sql.append("PARENT_ID");
        	sql.append(" = '");
        	sql.append(scriptID);
        	sql.append("'");
        	
			stat = conn.createStatement();
            rs = stat.executeQuery(sql.toString());
            
            while (rs.next())
                {
                scriptInfo = new HashMap<String, String>();

                for (int i = 1; i <= fields.size(); ++i)
                	{
                	String key = fields.get(i - 1);
	                String value = rs.getString(i);
	                
	                scriptInfo.put(key, value);
                	}
                }
        	}
        finally
	        {
            if (rs != null)
                rs.close();
			if (stat != null)
				conn.closeStatement(stat);
	        }
		
		return scriptInfo;
		}
	
	protected Map<String, String> getNewScriptInfo(JDBCPooledConnection conn, String scriptName) throws Exception
		{
		Map<String, String> scriptInfo = null;
		
		Statement stat = null;
        ResultSet rs = null;
        
        try
        	{
        	StringBuilder sql = new StringBuilder();
        	sql.append("select SCRIPT_ID, SCRIPT_NAME from workflow_config_xml where SCRIPT_NAME = '");
        	sql.append(scriptName);
        	sql.append("'");
        	
			stat = conn.createStatement();
            rs = stat.executeQuery(sql.toString());
            
            while (rs.next())
                {
                String sID = rs.getString(1);
                String sName = rs.getString(2);
                
                scriptInfo = new HashMap<String, String>();
                scriptInfo.put("SCRIPT_ID", sID);
                scriptInfo.put("SCRIPT_NAME", sName);
                }
        	}
        finally
	        {
            if (rs != null)
                rs.close();
			if (stat != null)
				conn.closeStatement(stat);
	        }
		
		return scriptInfo;
		}
	
	protected String createNewScript(JDBCPooledConnection conn, Map<String, String> oldScriptInfo, Map<String, String> oldBlockInfo) throws Exception
		{
		String newScriptID = null;
		VendorJDBC vJDBC = VendorSpecificJDBC.getVendorJDBC(conn.getConnection());
		
		DataManager dm = (DataManager) ResourceManager.getInstance().getResource(DataManager.RESOURCE_NAME);
		PrimaryKey key = new PrimaryKey(dm.getDataSource(), "WORKFLOW_CONFIG_XML");
		PrimaryKeyManager.createAPrimaryKey(conn.getConnection(), key);
		newScriptID = key.getPrimaryKey().getKey();
		
		String scriptName = oldScriptInfo.get("KEY");
		String scriptType = oldScriptInfo.get("SCRIPT_TYPE");
		if (scriptType == null)
			scriptType = "";
		String scriptDescription = oldScriptInfo.get("DESCRIPTION");
		if (scriptDescription == null)
			scriptDescription = "";
		
		StringBuilder scriptXMLBuilder = new StringBuilder();
		
		String oldScriptXML = oldScriptInfo.get("SCRIPT_XML");
		String oldBlockXML = oldBlockInfo.get("SCRIPT_XML");
		Document oldScriptDoc = null;
		if (oldScriptXML != null)
			{
			try
				{
				oldScriptDoc = XMLUtils.parseDocument(oldScriptXML);
				}
			catch (Exception e)
				{
				
				}
			}
		Document oldBlockDoc = null;
		if (oldBlockXML != null)
			{
			try
				{
				oldBlockDoc = XMLUtils.parseDocument(oldBlockXML);
				}
			catch (Exception e)
				{
				
				}
			}
		
		String runImmediately = null;
		if (oldScriptDoc != null)
			runImmediately = XMLUtils.evaluatePathAsValue(oldScriptDoc, "//run_immediately");
		String blockFragment = null;
		if (oldBlockDoc != null)
			blockFragment = XMLUtils.evaluatePathAsFragment(oldBlockDoc, "/");
		
		scriptXMLBuilder.append("<workflow-script>\n");
		scriptXMLBuilder.append("	<properties>\n");
		if (runImmediately != null)
			scriptXMLBuilder.append("		<run_immediately>").append(runImmediately).append("</run_immediately>\n");
		scriptXMLBuilder.append("	</properties>\n");
		if (blockFragment != null)
			scriptXMLBuilder.append(blockFragment);
		scriptXMLBuilder.append("</workflow-script>");
		
		PreparedStatement stat = null;
        
        try
        	{
        	StringBuilder sql = new StringBuilder();
        	sql.append("insert into workflow_config_xml (SCRIPT_ID, SCRIPT_NAME, DESCRIPTION, SCRIPT_TYPE, CREATED_BY, MODIFIED_BY, SCRIPT_XML, CREATION_STAMP, UPDATE_STAMP)");
			sql.append(" values (?, ?, ?, ?, ?, ?, ?, ");
			sql.append(vJDBC.getSQLCurrDateFunc());
        	sql.append(", ");
        	sql.append(vJDBC.getSQLCurrDateFunc());
        	sql.append(")");
        	
			stat = conn.prepareStatement(sql.toString());
			stat.setObject(1, newScriptID);
			stat.setObject(2, scriptName);
			stat.setObject(3, scriptDescription);
			stat.setObject(4, scriptType);
			stat.setObject(5, "System");
			stat.setObject(6, "System");
			stat.setObject(7, scriptXMLBuilder.toString());
			
            stat.executeQuery();
        	}
        finally
	        {
			if (stat != null)
				conn.closeStatement(stat);
	        }
		
		return newScriptID;
		}
	
	protected int updateScriptReference(JDBCPooledConnection conn, String updateField, String oldScriptID, String newScriptID) throws Exception
		{
		int refsChanged = 0;
		PreparedStatement stat = null;
		VendorJDBC vJDBC = VendorSpecificJDBC.getVendorJDBC(conn.getConnection());
        
        try
        	{
        	StringBuilder sql = new StringBuilder();
        	sql.append("update workflow_hierarchy set ");
        	sql.append(updateField);
        	sql.append(" = ?, time_stamp = ");
        	sql.append(vJDBC.getSQLCurrDateFunc());
        	sql.append(" WHERE ");
        	sql.append(updateField);
        	sql.append(" = ?");
        	
			stat = conn.prepareStatement(sql.toString());
			stat.setObject(1, newScriptID);
			stat.setObject(2, oldScriptID);
			
			refsChanged = stat.executeUpdate();
        	}
        finally
	        {
			if (stat != null)
				conn.closeStatement(stat);
	        }
		
		return refsChanged;
		}
	
	protected void touchWorkflowHierarchyAudit(JDBCPooledConnection conn) throws Exception
		{
		PreparedStatement stat = null;
		VendorJDBC vJDBC = VendorSpecificJDBC.getVendorJDBC(conn.getConnection());
		
		try
			{
			StringBuilder sql = new StringBuilder();
			
			sql.append("update mm_audit set date_modified = ");
			sql.append(vJDBC.getSQLCurrDateFunc());
			sql.append(" WHERE audit_id = ?");
			
			stat = conn.prepareStatement(sql.toString());
			stat.setObject(1, "WORKFLOW_HIERARCHY_STRUCTURE");
			
			stat.executeUpdate();
			}
		finally
			{
			if (stat != null)
				conn.closeStatement(stat);
			}
		}

	}