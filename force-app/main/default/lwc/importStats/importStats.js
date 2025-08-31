import { api, LightningElement, track } from 'lwc';
import { subscribe, unsubscribe, onError, } from 'lightning/empApi';

import getImportRecordData from '@salesforce/apex/DataImporterController.getImportRecordData';
import startImport from '@salesforce/apex/DataImporterController.startImport';

const IMPORT_PROGRESS_CHANNEL = '/event/ImportProgress__e';

export default class ImportStats extends LightningElement {
  @api fileInfo;
  @api columnMapping;
  @api importRecordId;

  @track isLoading = true;
  @track importData;

  @track subscription = {};

  get isProcessingStatus() {
    return this.importData?.status === 'Processing';
  }

  get isDraftStatus() {
    return this.importData?.status === 'Draft';
  }

  connectedCallback() {
    this.fetchImportData();
  }

  disconnectedCallback() {
    if (this.subscription) {
      unsubscribe(this.subscription, () => {
          console.log('Unsubscribed from platform event');
          this.subscription = null;
      });
    }
  }

  async fetchImportData() {
    try {
      const response = await getImportRecordData({ importRecordId: this.importRecordId });
      const data = JSON.parse(response);
      this.importData = data;

      this.handleSubscribe();

    } catch (error) {
      console.log('Error to fetch import record.');
      console.error(error);
    } finally {
      this.isLoading = false;
    }
  }

  async handleStartImport() {
    try {
      await startImport({ importRecordId: this.importRecordId });
    } catch (error) {
      console.log('Error to start import.');
      console.error(error);
    }
  }

  handleSubscribe() {
    const callback = (response) => {
      const { payload } = response.data;
      const importData = this.importData;
      if (this.importData.id === payload.ImportId__c) {
        if (payload.Status__c) importData.status = payload.Status__c;
        if (payload.TotalProcessed__c) importData.processedRows = payload.TotalProcessed__c;
        if (payload.TotalSuccess__c) importData.successRows = payload.TotalSuccess__c;
        if (payload.TotalErrors__c) importData.errorRows = payload.TotalErrors__c;

        this.importData = importData;
      }
    };

    subscribe(IMPORT_PROGRESS_CHANNEL, -1, callback).then(response => {
      console.log('Subscription to channel ' + IMPORT_PROGRESS_CHANNEL + ' is successful');
      this.subscription = response;
    });

    onError(error => {
      console.error('Error subscribing to platform event:', error);
    });
  }
}
