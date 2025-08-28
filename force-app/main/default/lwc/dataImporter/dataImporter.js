import { LightningElement, track } from 'lwc';

import { recordsMock } from './records-mock'

const STEPS = {
  SETUP_IMPORT: 'setup-import-step',
  MAPPING_COLUMNS: 'mapping-columns-step',
  DATA_PREVIEW: 'data-preview-step',
  RESULTS: 'results-step',
}

export default class DataImporter extends LightningElement {
  @track currentStep = STEPS.RESULTS;

  @track objectOptions = [
    { value: "Account", label: "Account" },
    { value: "Lead", label: "Lead" }
  ];

  @track targetObject;
  @track contentVersionId;

  @track previewColumns = [
    { label: "Account Name", fieldName: "Name" },
    { label: "Account Number", fieldName: "AccountNumber" },
    { label: "Phone", fieldName: "Phone" },
  ];
  @track previewData = recordsMock;

  get isSetupImportStep() {
    return this.currentStep === STEPS.SETUP_IMPORT;
  }

  get isMappingColumnsStep() {
    return this.currentStep === STEPS.MAPPING_COLUMNS;
  }

  get isDataPreviewStep() {
    return this.currentStep === STEPS.DATA_PREVIEW;
  }

  get isResultsStep() {
    return this.currentStep === STEPS.RESULTS;
  }

  get isTargetObjectNotSelected() {
    return !this.targetObject;
  }

  get acceptedFormats() {
    return ['.csv'];
  }

  changeToStep(stepName) {
    this.currentStep = stepName;
  }

  handleChange(event) {
    const { value } = event.detail;
    this.targetObject = value;
  }

  handleUploadFinished(event) {
    const { files } = event.detail;
    this.contentVersionId = files[0].contentVersionId;
    this.changeToStep(STEPS.MAPPING_COLUMNS);
  }
}
