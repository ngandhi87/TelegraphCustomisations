import com.picdar.resource.Core.*;
import com.picdar.resource.ConfigManager.Config;
import com.picdar.resource.CollectionManager.*;
import com.picdar.resource.HierarchicalDB.NodeNotFoundException;
import com.picdar.resource.WorkflowScriptManager.WorkflowScriptProgress;
import com.picdar.resource.WorkflowScriptManager.Actions.ActionResult;
import com.picdar.resource.WorkflowScriptManager.Actions.ActionResult.ActionResultStatus;
import com.picdar.resource.WorkflowScriptManager.Actions.Custom.*;
import com.picdar.resource.SecurityAccessManager.*;
import com.picdar.resource.SecurityAdminManager.*;
import com.picdar.resource.SecurityAccessManager.SecurityAccessManager.PolicyType;
import com.picdar.resource.SecurityManager.SecurityManagerException;
import com.picdar.resource.MISManager.MISLogger;
import com.picdar.resource.TransactionManager.TransactionHandle;

import com.picdar.common.DataSource.DataObject;
import com.picdar.common.DataSource.DataObjectArray;
import com.picdar.common.DataSource.PrimaryKey;
import com.picdar.common.Utilities.PicdarBoolean;
import com.picdar.common.Utilities.StringFormat;
import com.picdar.common.XMLSupport.Utils.XMLUtils;

import com.picdar.mogulsupport.Security.UserModel;

import java.util.*;

/*
This script is used to automatically remove policies on the assets linked to the folder that are being delete.
*/
public class RemovePoliciesFromAssetsWhenDeleteFolder extends com.picdar.resource.WorkflowScriptManager.Actions.Custom.CustomChangeAction
	{

	public RemovePoliciesFromAssetsWhenDeleteFolder()
		{
		}

	public boolean readScriptProperties(Properties props)
		{
		return true;
		}

	public int executeChange(DataObject actionObject, DataObjectArray memberLinks, DataObjectArray members, TransactionHandle transaction, List messageList)
		{
		try
			{

			String folderID = itsConfig.getConfigValue("/media-mogul-configuration/config/folderId");
			UserModel um = new UserModel("Administrator");

			logMessage("Moving/Deleting folder " + folderID, DEBUG);

			CollectionManager collMan = (CollectionManager) ResourceManager.getInstance().getResource("CategoryCollectionManager");
			SecurityAccessManager samMan = (SecurityAccessManager) ResourceManager.getInstance().getResource(SecurityAccessManager.RESOURCE_NAME);
			SecurityAdminManager secMan = (SecurityAdminManager) ResourceManager.getInstance().getResource(SecurityAdminManager.RESOURCE_NAME);

			String fullPath = collMan.getFullPathForNodeId(um, folderID);

			// find all assets linked to the folder including children folders
			List assets = collMan.getAssetsInCollection(um, fullPath, true);

			// find all the parent folders, then search their properties for the "auto-create-policies" flag
			DataObjectArray allParents = collMan.getCollectionsToRoot(um, fullPath);

			// run checks on the "auto-make-linked-assets-visible" folders and determine whether to remove policies
			int i = 0;
			CollectionInfo infoForFolderWithAutoVisibility = null;
			while (infoForFolderWithAutoVisibility == null && i < allParents.size())
				{
				CollectionInfo anObj = (CollectionInfo) allParents.get(i);
				String theProp = anObj.getNodeProperty("automatically-make-linked-assets-visible");
				if (theProp != null && PicdarBoolean.booleanValue(theProp))
					infoForFolderWithAutoVisibility = anObj;
				++i;
				}


			if (assets != null && assets.size() > 0 && infoForFolderWithAutoVisibility != null)
				{

				logMessage("No of assets linked to folder " + fullPath + " = " + assets.size(), DEBUG);
				logMessage("Found a parent folder that has the auto-visibility flag set - so checking for policies to remove", DEBUG);

				// get the owner and policies for the auto-visibility folder

				// the following is the list of roles IDs that we want to remove policies for					
				Set rolesForFolder = samMan.getRolesWithAccessToFolder(infoForFolderWithAutoVisibility.getPrimaryKey(), "category");
				Set usersForFolder = samMan.getUsersWithAccessToFolder(infoForFolderWithAutoVisibility.getPrimaryKey(), "category");
				logMessage("Found " + rolesForFolder.size() + " roles and " + usersForFolder .size() + " users with access to folder with auto-visibility", DEBUG);

				int j = 0;
				while (j < assets.size())
					{

					PrimaryKey objectKey = assets.get(j);

					PolicyTable policiesForAsset = samMan.getAssetPolicies(objectKey);
					logMessage("Found " + policiesForAsset.getActivePolicies().size() + " policies for asset " + objectKey.getKey(), DEBUG);

					boolean hasChangedPolicies = false;

					// go through each policy for the asset to consider removing it
					// if the policy is attached to the asset with auto-removal, then check it doesn't also belong to any other linked folder
					// if so, then remove it
					int polIndex = policiesForAsset.size() - 1;
					while (polIndex >= 0)
						{
						Policy assPol = policiesForAsset.getPolicy(polIndex);
						boolean foundMatchForAssetPolicy = false;
							
						// look for a folder policy with the same ID
						if (assPol.getRoleId() != null && !assPol.getRoleId().isEmpty())
							{
							Iterator iter = rolesForFolder.iterator();
							int ptIndex = 0;
							while (!foundMatchForAssetPolicy && iter.hasNext())
								{
								String folderRole = (String) iter.next();
								if (assPol.getRoleId().equals(folderRole))
									foundMatchForAssetPolicy = true;
								++ptIndex;
								}
							}
						else if (assPol.getUserId() != null && !assPol.getUserId().isEmpty())
							{
							Iterator iter = usersForFolder.iterator();
							int ptIndex = 0;
							while (!foundMatchForAssetPolicy && iter.hasNext())
								{
								String folderUser = (String) iter.next();
								if (assPol.getUserId().equals(folderUser))
									foundMatchForAssetPolicy = true;
								++ptIndex;
								}
							}							

						if (foundMatchForAssetPolicy)
							{
							// check if another folder has this....if so, DON'T remove
							// get all the folders linked to the asset - this doesn't include the folder it's just been unlinked from
							List folders = collMan.getCollectionsContainingAssetAsNodeIds(um, objectKey);

							// remove this folder being deleted from the list
							folders.remove(folderID);

							logMessage("Found a policy on asset " + objectKey.getKey() + " which is a candidate for removal. Check against " + folders.size() + " other folder links.", DEBUG);

							// get all of the owners for these folders...so that we don't remove it if it was made visible
							boolean okToDeletePolicy = true;

							int folderIndex = 0;
							while (okToDeletePolicy && folderIndex < folders.size())
								{
								String nodeID = (String) folders.get(folderIndex);
								String linkedFolderWithVisID = null;

								String thisFolderFullPath = collMan.getFullPathForNodeId(um, nodeID);

								if (!thisFolderFullPath.contains(fullPath))
									{
									allParents = collMan.getCollectionsToRoot(um, thisFolderFullPath);
									int k = 0;
									while (linkedFolderWithVisID == null && k < allParents.size())
										{
										CollectionInfo anObj = (CollectionInfo) allParents.get(k);
										String theProp = anObj.getNodeProperty("automatically-make-linked-assets-visible");
										if (theProp != null && PicdarBoolean.booleanValue(theProp))
											linkedFolderWithVisID = anObj.getPrimaryKey().getKey();
										++k;
										}

									if (linkedFolderWithVisID != null)
										{
										CollectionInfo aFolder = collMan.getCollectionInfoWithId(um, linkedFolderWithVisID);

										Set rolesForOtherFolder = samMan.getRolesWithAccessToFolder(aFolder.getPrimaryKey(), "category");
										Iterator iter = rolesForOtherFolder.iterator();
										int ptIndex = 0;
										while (okToDeletePolicy && iter.hasNext())
											{
											String folderPol = (String) iter.next();
											if (assPol.getRoleId().equals(folderPol))
												okToDeletePolicy = false;

											++ptIndex;
											}
											
										if (okToDeletePolicy)
											{
											Set usersForOtherFolder = samMan.getUsersWithAccessToFolder(aFolder.getPrimaryKey(), "category");
											iter = usersForOtherFolder.iterator();
											ptIndex = 0;
											while (okToDeletePolicy && iter.hasNext())
												{
												String folderPol = (String) iter.next();
												if (assPol.getUserId().equals(folderPol))
													okToDeletePolicy = false;
												++ptIndex;
												}
											}												
										}
									else
										{
										logMessage("This folder " + thisFolderFullPath + " will not be checked as it is a child of folder " + fullPath + " being deleted/moved", DEBUG);
										}
									}
									++folderIndex;
								}

							// remove the policy
							if (okToDeletePolicy)
								{
								logMessage("Removing policy because asset is not linked to any other folder that has this owner.", DEBUG);
								policiesForAsset.removePolicy(polIndex);
								hasChangedPolicies = true;
								}
							else
								logMessage("Decided not to delete policy because asset is linked to another folder that has this owner.", DEBUG);
							}
						--polIndex;
						}

					if (hasChangedPolicies)
						{
						// delete all policies for asset and re-add from table?
						// cannot find an update that takes the table...
						HashMap itemPolicies = new HashMap<PrimaryKey, List<Policy>>();
						ArrayList polList = new ArrayList();
						int polIndex2 = 0;
						while (polIndex2 < policiesForAsset.size())
							{
							polList.add(policiesForAsset.get(polIndex2));
							++polIndex2;
							}
						itemPolicies.put(objectKey, polList);
						samMan.deletePolicies(objectKey, PolicyType.ASSET);
						samMan.addPolicies(itemPolicies);
						}

					++j;
					}
				}
			}

		catch (Throwable t)
			{
			logMessage("Failed:" + t.getMessage(), ERROR);
			}

		return CustomAction.RESULT_NO_ACTION;
		}

	}
