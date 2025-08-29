import { api, LightningElement, track } from 'lwc';

export default class SetupImport extends LightningElement {
  @api contentVersionId;

  @track targetObject;
  @track objectOptions = [
    { value: "Account", label: "Account" },
    { value: "Lead", label: "Lead" }
  ];

  get acceptedFormats() {
    return ['.csv'];
  }

  get isTargetObjectNotSelected() {
    return !this.targetObject;
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
