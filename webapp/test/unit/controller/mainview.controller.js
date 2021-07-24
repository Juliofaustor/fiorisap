/*global QUnit*/

sap.ui.define([
	"juliofg/invoices/controller/mainview.controller"
], function (Controller) {
	"use strict";

	QUnit.module("mainview Controller");

	QUnit.test("I should test the mainview controller", function (assert) {
		var oAppController = new Controller();
		oAppController.onInit();
		assert.ok(oAppController);
	});

});
