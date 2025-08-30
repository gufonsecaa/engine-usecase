import { LightningElement, track, wire } from 'lwc';

import getFileInfo from '@salesforce/apex/DataImporterController.getFileInfo';

const STEPS = {
  SETUP_IMPORT: 'setup-import-step',
  MAPPING_COLUMNS: 'mapping-columns-step',
  PREVIEW_IMPORT: 'preview-import-step',
  RESULTS: 'results-step',
}

export default class DataImporter extends LightningElement {
  @track currentStep = STEPS.SETUP_IMPORT;

  @track targetObject;
  @track contentVersionId;
  @track columnMapping;

  @track fileInfo;

  get isSetupImportStep() {
    return this.currentStep === STEPS.SETUP_IMPORT;
  }

  get isMappingColumnsStep() {
    return this.currentStep === STEPS.MAPPING_COLUMNS;
  }

  get isPreviewImportStep() {
    return this.currentStep === STEPS.PREVIEW_IMPORT;
  }

  get isResultsStep() {
    return this.currentStep === STEPS.RESULTS;
  }

  @wire(getFileInfo, { contentVersionId: '$contentVersionId' })
  wiredFileInfo({ data, error }) {
    if (error) {
      console.log('Error to load file data.');
      console.error(error);
      return;
    }

    if (data) {
      const file = JSON.parse(data);
      this.fileInfo = file;
    }
  }

  changeToStep(stepName) {
    this.currentStep = stepName;
  }

  handleSetupFinished(event) {
    const { targetObject, contentVersionId } = event.detail;

    this.targetObject = targetObject;
    this.contentVersionId = contentVersionId;

    this.changeToStep(STEPS.MAPPING_COLUMNS);
  }

  handleMappingFinished(event) {
    const { columnMapping } = event.detail;

    this.columnMapping = columnMapping;

    this.changeToStep(STEPS.PREVIEW_IMPORT);
  }

  handlePreviewImportFinished(event) {
    this.changeToStep(STEPS.RESULTS);
  }
}
