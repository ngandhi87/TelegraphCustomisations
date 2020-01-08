package com.groovytest;
import java.io.File;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import org.apache.commons.io.FileUtils;
import org.apache.commons.lang3.StringUtils;

import com.picdar.common.DataSource.DataObject;
import com.picdar.common.DataSource.DataObjectArray;
import com.picdar.common.Utilities.DateUtils;
import com.picdar.process2.Core.ProcessItem;
import com.picdar.process2.Core.ProcessModuleData;
import com.picdar.resource.MISManager.MISManager;

public class PreparePDFExportSummary extends com.picdar.process2.Processing.ScriptProcessor.ProcessModuleScript {
	
	public final static String EXPORT_SUMMARY_OBJECT_PROP = "export-summary-object";
	public final static String EXPORT_FILENAME_FIELD_PROP = "export-filename-field";
	public final static String EXPORT_FILE_TIMESTAMP_FIELD_PROP = "export-file-timestamp-field";
	public final static String PUBLICATION_TITLE_PROP = "publication-title";
	public final static String PUBLICATION_BOOK_PROP = "publication-book";
	public final static String PUBLICATION_START_DATE_PROP = "publication-start-date";
	public final static String PUBLICATION_END_DATE_PROP = "publication-end-date";
	public final static String EXPORT_LOCATION_PROP = "export-location";
	public final static String EMAIL_CONTENT_OBJECT_PROP = "email-content-object";

	public PreparePDFExportSummary(HashMap props)
		{
		super(props);
		}
	
	@Override
	public void execute(ProcessItem itemToProcess, ProcessModuleData processData) 
		{
		
		String dataName = itsModuleProperties.getProperty(EXPORT_SUMMARY_OBJECT_PROP);

		Object theDataObject = (dataName == null || dataName.length() == 0 ? null : itemToProcess.getObject(dataName));
		if (theDataObject == null ||  
			(!((theDataObject instanceof DataObjectArray) && (!((DataObjectArray) theDataObject).isEmpty()))))
			{
			String message = "Object '" + dataName + "' is either null or not a DataObjectArray.";
			logMessage("PreparePDFExportSummary: " + message + "  Taking no action for:  " + itemToProcess.getKey(), MISManager.PRIORITY_WARNING);
			rejectItem(itemToProcess, message);
			}
		else
			{
			DataObjectArray summaryObjectArray = (DataObjectArray)theDataObject;
		
			String exportFilenameField = itsModuleProperties.getProperty(EXPORT_FILENAME_FIELD_PROP);
			logMessage("PreparePDFExportSummary: Configured export filename field - " + exportFilenameField, MISManager.PRIORITY_DEBUG);
			if (StringUtils.isBlank(exportFilenameField))
				{
				exportFilenameField = "7_EXPORT_FILENAME";
				logMessage("PreparePDFExportSummary: Configured export filename field is empty, using default value of " + exportFilenameField, MISManager.PRIORITY_DEBUG);
				}
			
			String exportFileTimestampField = itsModuleProperties.getProperty(EXPORT_FILE_TIMESTAMP_FIELD_PROP);
			logMessage("PreparePDFExportSummary: Configured export file timestamp field - " + exportFileTimestampField, MISManager.PRIORITY_DEBUG);
			if (StringUtils.isBlank(exportFileTimestampField))
				{
				exportFileTimestampField = "8_LATEST_EXPORT_TIMESTAMP";
				logMessage("PreparePDFExportSummary: Configured export file timestamp field is empty, using default value of " + exportFileTimestampField, MISManager.PRIORITY_DEBUG);
				}

			String pubTitle = itsModuleProperties.getProperty(PUBLICATION_TITLE_PROP);
			logMessage("PreparePDFExportSummary: Configured publication title - " + pubTitle, MISManager.PRIORITY_DEBUG);
			
			String pubBook = itsModuleProperties.getProperty(PUBLICATION_BOOK_PROP);
			logMessage("PreparePDFExportSummary: Configured publication book - " + pubBook, MISManager.PRIORITY_DEBUG);
			
			String pubStartDate = itsModuleProperties.getProperty(PUBLICATION_START_DATE_PROP);
			logMessage("PreparePDFExportSummary: Configured publication start date - " + pubStartDate, MISManager.PRIORITY_DEBUG);
	
			String pubEndDate = itsModuleProperties.getProperty(PUBLICATION_END_DATE_PROP);
			logMessage("PreparePDFExportSummary: Configured publication end date - " + pubEndDate, MISManager.PRIORITY_DEBUG);
	
			String exportLocation = itsModuleProperties.getProperty(EXPORT_LOCATION_PROP);
			logMessage("PreparePDFExportSummary: Configured export location - " + exportLocation, MISManager.PRIORITY_DEBUG);
			
			String emailContentObjectName = itsModuleProperties.getProperty(EMAIL_CONTENT_OBJECT_PROP);
			logMessage("PreparePDFExportSummary: Configured email content object name - " + emailContentObjectName, MISManager.PRIORITY_DEBUG);
			
			File exportDir = new File(exportLocation);
			if (!exportDir.exists())  
				{
				logMessage("PreparePDFExportSummary: Export location - " + exportLocation + " does not exist!", MISManager.PRIORITY_ERROR);
				} 
			else 
				{
				if (!exportDir.canRead()) 
					{
					logMessage("PreparePDFExportSummary: CHP cannot access export location - " + exportLocation, MISManager.PRIORITY_ERROR);
					} 
				else 
					{
					String[] extensions = new String[1];
					extensions[0] = "pdf";
					
					Collection exportPDFFiles = FileUtils.listFiles(exportDir, extensions, false);
					
					Map exportPDFMap = new HashMap();
					int noOfFileInExportDir = 0;
					
					List emptyFiles = new ArrayList();

					if (exportPDFFiles != null && !exportPDFFiles.isEmpty())  
						{
						noOfFileInExportDir = exportPDFFiles.size();
						
						Iterator exportPDFIter = exportPDFFiles.iterator();
						while (exportPDFIter.hasNext()) 
							{
							File exportPDFFile = (File)exportPDFIter.next();
							
							String lastModifiedStr = DateUtils.formatCustomDate(new Date(exportPDFFile.lastModified()), null, "dd/MM/yyyy HH:mm:ss");
							exportPDFMap.put(exportPDFFile.getName(), lastModifiedStr);
							
							if (exportPDFFile.length() == 0)
								{
								logMessage("PreparePDFExportSummary: " + exportPDFFile.getName() + " is zero byte.", MISManager.PRIORITY_WARNING);
								emptyFiles.add(exportPDFFile.getName());
								}
							}
						}
					else
						{
						logMessage("PreparePDFExportSummary: Cannot find pdf file in export location - " + exportLocation, MISManager.PRIORITY_WARNING);
						}

					int i = 0;
					
					Iterator summaryIter = summaryObjectArray.iterator();
					while (summaryIter.hasNext())
						{
						DataObject pdfRecord = (DataObject)summaryIter.next();
						if (i > 0) // skip the header record
							{
							String exportFilename = pdfRecord.getAttributeAsString(exportFilenameField);
							if (StringUtils.isNotBlank(exportFilename))
								{
								if (exportPDFMap.containsKey(exportFilename)) 
									{
									// update file timestamp from actual file
									pdfRecord.setAttribute(exportFileTimestampField, exportPDFMap.get(exportFilename));
									}
								else
									{
									// the pdf file doesn't exist in export location, update the report record to remove export filename and timestamp
									pdfRecord.setAttribute(exportFilenameField, " ");
									pdfRecord.setAttribute(exportFileTimestampField, " ");
									}
								}
							}
						i++;
						}
					
					int noOfFileExpectedExport = i - 1;
					
					StringBuilder emailBody = new StringBuilder("Below is summary of PDF export for ...");
					emailBody.append("\n\n").append("Publication Tile: ").append(pubTitle); 
					emailBody.append("\n").append("Publication Book Name: ").append(pubBook); 
					emailBody.append("\n").append("Publication Start Date: ").append(pubStartDate); 
					emailBody.append("\n").append("Publication End Date: ").append(pubEndDate);
					emailBody.append("\n\n").append("Number of PDFs Expected for Export: ").append(noOfFileExpectedExport);
					emailBody.append("\n").append("Number of PDFs in Export Location ").append(exportLocation).append(" : ").append(noOfFileInExportDir);				
					
					emailBody.append("\n\n").append("Please find spreadsheet attached for the export details."); 
					
					if (!emptyFiles.isEmpty()) {
						emailBody.append("\n\nNote: following files are empty ...");
						Iterator emptyFilesIter = emptyFiles.iterator();
						while (emptyFilesIter.hasNext()) 
							{
							String emptyFile = (String)emptyFilesIter.next();
							emailBody.append("\n").append(emptyFile);
							}
						emailBody.append("\n\n");
					}
					
					logMessage("PreparePDFExportSummary:\n" + emailBody.toString(), MISManager.PRIORITY_INFO);
					
					itemToProcess.setObject(emailContentObjectName, emailBody.toString());
					}
				}
			}
		}

}
