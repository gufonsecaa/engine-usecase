import { api, track } from 'lwc';
import LightningModal from 'lightning/modal';

export default class MapColumnModal extends LightningModal {
  /**
    columnName,
    allFields,
    mappedColumns
   */
  @api content;

  @track selectedField;

  get unmapColum() {
    if (!this.selectedField) return null;

    if (this.selectedField) {
      const fieldAlreadyMapped = this.content
        .mappedColumns?.find(
          mappedColumn => mappedColumn.field?.apiName === this.selectedField
        );

      if (fieldAlreadyMapped) {
        return fieldAlreadyMapped.csvColumn;
      }
    }

    return null;
  }

  get options() {
    return this.content?.allFields.map(field => ({
      label: `${field.label} (${field.apiName})`,
      value: field.apiName
    }))
  }

  handleSelect(event) {
    const { value } = event.detail;
    this.selectedField = value;
  }

  handleConfirm() {
    const field = this.content.allFields.find(field => field.apiName === this.selectedField);
    this.close({
      selectedField: field,
      unmapColum: this.unmapColum
    });
  }
}
