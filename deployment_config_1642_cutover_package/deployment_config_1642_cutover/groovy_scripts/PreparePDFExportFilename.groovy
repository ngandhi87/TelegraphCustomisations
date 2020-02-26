package com.groovytest;
import java.util.Date;
import java.util.HashMap;
import java.util.StringTokenizer;

import org.apache.commons.lang3.StringUtils;

import com.picdar.common.DataSource.DataObject;
import com.picdar.common.DataSource.DataObjectArray;
import com.picdar.common.Utilities.DateUtils;
import com.picdar.process2.Core.ProcessItem;
import com.picdar.process2.Core.ProcessModuleData;
import com.picdar.resource.MISManager.MISManager;

public class PreparePDFExportFilename extends com.picdar.process2.Processing.ScriptProcessor.ProcessModuleScript {
	
	public final static String DATAOBJECT_PROP = "dataobject";
	public final static String OUTPUT_FIELD_PROP = "output-field";
	public final static String FILENAME_TEMPLATE_PROP = "filename-template";
	
	public PreparePDFExportFilename(HashMap props)
		{
		super(props);
		}
	
	@Override
	public void execute(ProcessItem itemToProcess, ProcessModuleData processData) 
		{
		
        try 
        	{
			
			String dataName = itsModuleProperties.getProperty(DATAOBJECT_PROP);

			Object theDataObject = (dataName == null || dataName.length() == 0 ? null : itemToProcess.getObject(dataName));
			if (theDataObject == null || (!(theDataObject instanceof DataObject) &&
				(!((theDataObject instanceof DataObjectArray) && (!((DataObjectArray) theDataObject).isEmpty())))))
				logMessage("PreparePDFExportFilename:  Object '" + dataName + "' is either null or not a DataObject or not a DataObjectArray.  Taking no action for:  " + itemToProcess.getKey(), MISManager.PRIORITY_WARNING);
			else
				{
				DataObject dataObject = (theDataObject instanceof DataObject ? (DataObject) theDataObject : ((DataObjectArray) theDataObject).get(0));
				
				logMessage("PreparePDFExportFilename: Object with primary key - " + dataObject.getPrimaryKey().getKey(), MISManager.PRIORITY_DEBUG);

				String outputFiled = itsModuleProperties.getProperty(OUTPUT_FIELD_PROP);
				logMessage("PreparePDFExportFilename: Configured output field - " + outputFiled, MISManager.PRIORITY_DEBUG);
			
				String filenameTemplate = itsModuleProperties.getProperty(FILENAME_TEMPLATE_PROP);
				logMessage("PreparePDFExportFilename: Configured filename template - " + filenameTemplate, MISManager.PRIORITY_DEBUG);
					
				if (StringUtils.isNotBlank(filenameTemplate))
					{
					String newFilename = expandTemplate(filenameTemplate, dataObject);
					logMessage("PreparePDFExportFilename: newFilename = " + newFilename, MISManager.PRIORITY_INFO);
					
					if (StringUtils.isNotBlank(newFilename))
						{
						dataObject.setAttribute(outputFiled, newFilename);
						}
					else 
						{
						String errorMessage = "Error creating export filename as some of required value is missing or filename template is not in correct format";
						logMessage("PreparePDFExportFilename: " + errorMessage + " for " + dataObject.getPrimaryKey().getKey(), MISManager.PRIORITY_ERROR);
						rejectItem(itemToProcess, errorMessage);
						}
					}
				else
					{
					String errorMessage = "Error creating export filename as filename template is blank";
					logMessage("PreparePDFExportFilename: " + errorMessage + " for " + dataObject.getPrimaryKey().getKey(), MISManager.PRIORITY_ERROR);
					rejectItem(itemToProcess, errorMessage);
					}
				}
			
        	} 
        catch (Exception e) 
        	{
			String errorMessage = "Error creating export filename";
			logMessage("PreparePDFExportFilename: " + errorMessage + " ::: " + e.getMessage(), MISManager.PRIORITY_ERROR);
			rejectItem(itemToProcess, errorMessage);
        	}
		}
	
	private String expandTemplate(String template, DataObject dataObject)
		{
		StringBuilder expandedValue = new StringBuilder();
		int currPos = 0;
		boolean finished = false;
		while (!finished)
			{
			int nextTag = template.indexOf("[", currPos);
			if (nextTag == -1)
				{
				expandedValue.append(template.substring(currPos));
				finished = true;
				}
			else
				{
				int endOfTag = template.indexOf("]", nextTag + 1);
				if (endOfTag == -1)
					{
					return null;
					}
				else
					{
					expandedValue.append(template.substring(currPos, nextTag));
	
					String tag = template.substring(nextTag + 1, endOfTag);
					currPos = endOfTag + 1;
	
					StringTokenizer strTok = new StringTokenizer(tag, ":");
					String fieldName = null, tagType = null, tagArg = null;
					try
						{
						fieldName = strTok.nextToken();
						tagType = strTok.nextToken();
						tagArg = strTok.nextToken();
						}
					catch (Exception e)
						{
						// missing values handled later on
						}
	
					if (("date").equalsIgnoreCase(tagType))
						{
						Date dateVal = dataObject.getAttributeAsDate(fieldName);
						logMessage("PreparePDFExportFilename: value of field " + fieldName + " = " + dateVal, MISManager.PRIORITY_DEBUG);
						if (dateVal == null)
							{
							return null;
							}
						
						String fieldVal = DateUtils.formatCustomDate(dateVal, null, tagArg);
						expandedValue.append(fieldVal);
						}
					else if (("zeroPadding").equalsIgnoreCase(tagType))
						{
						String fieldVal = dataObject.getAttributeAsString(fieldName);
						logMessage("PreparePDFExportFilename: value of field " + fieldName + " = " + fieldVal, MISManager.PRIORITY_DEBUG);
						if (StringUtils.isBlank(fieldVal))
							{
							return null;
							}

						String transformedValue = "";
						Integer paddingSize;

						try
							{
							paddingSize = Integer.valueOf(tagArg);
							}
						catch (NumberFormatException ne)
							{
							paddingSize = 4;
							logMessage("PreparePDFExportFilename: " + tagArg + " is not valid number, will use default value padding size - " + paddingSize, MISManager.PRIORITY_INFO);
							}
						
						if (fieldVal.contains(",")) 
							{
							for (String v : fieldVal.split(",")) 
								{
								transformedValue = transformedValue + StringUtils.leftPad(v, paddingSize, "0");
								}
							}
						else
							{
							transformedValue = StringUtils.leftPad(fieldVal, paddingSize, "0");
							}
						expandedValue.append(transformedValue);
						}
					else
						{
						String fieldVal = dataObject.getAttributeAsString(fieldName);
						logMessage("PreparePDFExportFilename: value of field " + fieldName + " = " + fieldVal, MISManager.PRIORITY_DEBUG);
						if (StringUtils.isBlank(fieldVal))
							{
							return null;
							}
						expandedValue.append(fieldVal);
						}
					}
				}
			}
		return expandedValue.toString();
		}

}
