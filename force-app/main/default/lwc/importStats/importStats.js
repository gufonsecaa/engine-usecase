import { api, LightningElement } from 'lwc';

export default class ImportStats extends LightningElement {
  @api columnMapping;

  get totalColumns() {
    return this.columnMapping.length;
  }

  get totalMappedColumns() {
    return this.columnMapping.filter(column => column.field).length;
  }
}
