import { api, LightningElement, track } from 'lwc';

import getAvailableSObjectOptions from '@salesforce/apex/DataImporterController.getAvailableSObjectOptions';

export default class SetupImport extends LightningElement {
  @api contentVersionId;

  @track targetObject;
  @track objectOptions = [];

  get acceptedFormats() {
    return ['.csv'];
  }

  get isTargetObjectNotSelected() {
    return !this.targetObject;
  }

  connectedCallback() {
    this.fetchAvailableObjectOptions();
  }

  async fetchAvailableObjectOptions() {
    try {
      const result = await getAvailableSObjectOptions();
      const options = JSON.parse(result).sort((a, b) => a.label.localeCompare(b.label));
      this.objectOptions = options;
    } catch (error) {
      console.error(error);
    }
  }

  handleChange(event) {
    const { value } = event.detail;
    this.targetObject = value;
  }

  handleUploadFinished(event) {
    const { files } = event.detail;
    this.contentVersionId = files[0].contentVersionId;

    this.dispatchEvent(new CustomEvent('setupfinished', {
      detail: {
        targetObject: this.targetObject,
        contentVersionId: this.contentVersionId
      }
    }));
  }
}
