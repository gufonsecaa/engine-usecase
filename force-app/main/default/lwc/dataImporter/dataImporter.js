import { LightningElement, track } from 'lwc';

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
