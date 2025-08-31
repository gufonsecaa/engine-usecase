import { api, LightningElement, track } from 'lwc';

import getImportRecordData from '@salesforce/apex/DataImporterController.getImportRecordData';

export default class ImportStats extends LightningElement {
  @api fileInfo;
  @api columnMapping;
  @api importRecordId;

  @track isLoading = true;
  @track importData;

  get isProcessingStatus() {
    return this.importData?.status === 'Processing';
  }

  get isDraftStatus() {
    return this.importData?.status === 'Draft';
  }

  connectedCallback() {
    this.fetchImportData();
  }

  async fetchImportData() {
    try {
      const response = await getImportRecordData({ importRecordId: this.importRecordId });
      const data = JSON.parse(response);
      this.importData = data;
    } catch (error) {
      console.log('Error to fetch import record.');
      console.error(error);
    } finally {
      this.isLoading = false;
    }
  }

  async handleStartImport() {

  }
}
