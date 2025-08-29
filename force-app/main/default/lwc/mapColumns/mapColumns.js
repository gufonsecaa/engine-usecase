import { api, LightningElement, track, wire } from 'lwc';
import { getObjectInfo } from "lightning/uiObjectInfoApi";

import getCSVColumnNames from "@salesforce/apex/DataImporterController.getCSVColumnNames";

import MapColumnModal from 'c/mapColumnModal';

export default class MapColumns extends LightningElement {

  @api targetObject = null;

  @track allFields = [];
  @track columnMapping = [];

  @wire(getObjectInfo, { objectApiName: '$targetObject' })
  wiredObjectInfo({ data, error }) {
    if (error) {
      console.error(error);
    }

    if (data) {
      const allFields = Object.values(data?.fields);

      this.allFields = allFields
        .filter((field) => field.createable && field.updateable)
        .map((field) => {
          return {
            label: field.label,
            apiName: field.apiName,
            externalId: field.externalId,
            unique: field.unique,
            dataType: field.dataType
          }
        });
    }
  }

  connectedCallback() {
    this.fetchCSVColumnNames();
  }

  async fetchCSVColumnNames() {
    try {
      const result = await getCSVColumnNames();
      const csvColumns = JSON.parse(result);

      this.columnMapping = csvColumns.map(column => ({
        csvColumn: column,
        field: null
      }));
    } catch (error) {
      console.log(error);
    }
  }

  async handleMapFieldModal(event) {
    const { columnName } = event.target.dataset;

    const response = await MapColumnModal.open({
      size: 'small',
      content: {
        columnName,
        allFields: this.allFields,
        mappedColumns: this.columnMapping.filter(column => !!column.field)
      }
    });

    if (response && response.selectedField) {
      this.columnMapping = this.columnMapping.map(column => {
        if (column.csvColumn === columnName) {
          return {
            ...column,
            field: response.selectedField
          }
        }

        if (response.unmapColum && response.unmapColum === column.csvColumn) {
          return {
            ...column,
            field: null
          }
        }

        return column;
      });
    }
  }

  handleMappingFinished() {
    this.dispatchEvent(new CustomEvent('mappingfinished', {
      detail: {
        columnMapping: this.columnMapping
      }
    }));
  }
}
