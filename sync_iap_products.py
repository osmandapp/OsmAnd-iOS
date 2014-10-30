#!/usr/bin/python
# -*- coding: utf-8 -*

import sys
import os
import argparse
import getpass
import subprocess
import tempfile
import xml.etree.ElementTree as ET
import shutil
import locale
import re
import time
import hashlib

# =============================================================================================================================================================
# =============================================================================================================================================================
# =============================================================================================================================================================

class ProductsSynchronizer(object):
    # ---------------------------------------------------------------------------------------------------------------------------------------------------------
    def __init__(self, iTMSTransporterExecutablePath):
    	ET.register_namespace("", "http://apple.com/itunes/importer")
    	self.iTMSTransporterExecutablePath = iTMSTransporterExecutablePath
    	self.priceTiers = {
    		0 : 0, # Free
    		1 : 1, # Country
    		2 : 4, # Large country
    		3 : 6, # "part of world"
    		4 : 16 # "world"
    	}
    	self.allowedLanguages = [
			"da-DK",
			"de-DE",
			"el-GR",
			"en-AU",
			"en-CA",
			"en-GB",
			"en-US",
			"es-ES",
			"es-MX",
			"fi-FI",
			"fr-CA",
			"fr-FR",
			"id-ID",
			"it-IT",
			"ja-JP",
			"ko-KR",
			"ms-MY",
			"nl-NL",
			"no-NO",
			"pt-BR",
			"pt-PT",
			"ru-RU",
			"sv-SE",
			"th-TH",
			"tr-TR",
			"vi-VI",
			"cmn-Hans",
			"cmn-Hant"
    	]

    # ---------------------------------------------------------------------------------------------------------------------------------------------------------
    def synchronize(self, productsXmlFilename, applicationSKU, appleId, password):
    	# Obtain current metadata of the application
    	currentMetadata = self.lookupMetadata(applicationSKU, appleId, password)
    	updatedMetadata = currentMetadata

    	# Remove old versions of products
    	updatedMetadata = self.removeInAppPurchaseProducts(updatedMetadata, "region:")

    	# Update metadata
    	self.saveMetadata(applicationSKU, updatedMetadata)
    	self.verifyMetadata(applicationSKU, appleId, password)
    	self.uploadMetadata(applicationSKU, appleId, password)

    	# Add new products
    	regionsAsProducts = self.readProducts(productsXmlFilename)
    	updatedMetadata = self.insertInAppPurchaseProducts(applicationSKU, updatedMetadata, regionsAsProducts)

    	# Update metadata
    	self.saveMetadata(applicationSKU, updatedMetadata)
    	self.verifyMetadata(applicationSKU, appleId, password)
    	self.uploadMetadata(applicationSKU, appleId, password)

    	# Cleanup
    	self.cleanup(applicationSKU)

    	return True

    # ---------------------------------------------------------------------------------------------------------------------------------------------------------
    def lookupMetadata(self, applicationSKU, appleId, password):
    	# Execute iTMSTransported to get metadata
    	subprocess.call([
    		self.iTMSTransporterExecutablePath,
    		"-m", "lookupMetadata",
    		"-u", appleId,
    		"-p", password,
    		"-vendor_id", applicationSKU,
    		"-destination", tempfile.gettempdir()])

    	# Read entire content of the file
    	with open(os.path.abspath(tempfile.gettempdir() + "/" + applicationSKU + ".itmsp/metadata.xml"), "r") as metadataFile:
    		metadata = metadataFile.read()

    	return metadata

    # ---------------------------------------------------------------------------------------------------------------------------------------------------------
    def cleanup(self, applicationSKU):
    	# Delete entire directory
    	shutil.rmtree(tempfile.gettempdir() + "/" + applicationSKU + ".itmsp")

    # ---------------------------------------------------------------------------------------------------------------------------------------------------------
    def saveMetadata(self, applicationSKU, metadata):
    	# Write entire content to a file
    	with open(os.path.abspath(tempfile.gettempdir() + "/" + applicationSKU + ".itmsp/metadata.xml"), "w") as metadataFile:
    		metadataFile.write(metadata)

    # ---------------------------------------------------------------------------------------------------------------------------------------------------------
    def verifyMetadata(self, applicationSKU, appleId, password):
    	# Execute iTMSTransported to get metadata
    	subprocess.call([
    		self.iTMSTransporterExecutablePath,
    		"-m", "verify",
    		"-u", appleId,
    		"-p", password,
    		"-f", os.path.abspath(tempfile.gettempdir() + "/" + applicationSKU + ".itmsp")])

    # ---------------------------------------------------------------------------------------------------------------------------------------------------------
    def uploadMetadata(self, applicationSKU, appleId, password):
    	# Execute iTMSTransported to get metadata
    	subprocess.call([
    		self.iTMSTransporterExecutablePath,
    		"-m", "upload",
    		"-u", appleId,
    		"-p", password,
    		"-f", os.path.abspath(tempfile.gettempdir() + "/" + applicationSKU + ".itmsp")])

    # ---------------------------------------------------------------------------------------------------------------------------------------------------------
    def removeInAppPurchaseProducts(self, metadata, productReferenceNamePrefix=""):
    	xmlMetadataRoot = ET.fromstring(metadata)

    	xmlSoftwareMetadata = xmlMetadataRoot.find(
    		"./{http://apple.com/itunes/importer}software" +
    		"/{http://apple.com/itunes/importer}software_metadata")
    	xmlProducts = xmlSoftwareMetadata.find("{http://apple.com/itunes/importer}in_app_purchases");

    	if xmlProducts != None:
    		for xmlProduct in xmlProducts.findall("./{http://apple.com/itunes/importer}in_app_purchase"):
    			referenceName = xmlProduct.find("{http://apple.com/itunes/importer}reference_name").text
    			if not referenceName.startswith(productReferenceNamePrefix):
    				continue
    			xmlProducts.remove(xmlProduct)

    		# In case all products were removed, remove parent tag
    		try:
    			productsIterator = xmlProducts.iter()
    			next(productsIterator)
    			next(productsIterator)
    		except StopIteration:
    			xmlSoftwareMetadata.remove(xmlProducts)

    	return '<?xml version="1.0" encoding="UTF-8"?>\n' + ET.tostring(xmlMetadataRoot, encoding="utf-8").decode("utf-8")

    # ---------------------------------------------------------------------------------------------------------------------------------------------------------
    class RegionAsProduct(object):
    	def __init__(self, regionId, priceTier, name, localizedNames=dict()):
    		if regionId == "":
    			regionId = "planet_earth"
    		self.regionId = regionId
    		self.priceTier = priceTier
    		self.name = name
    		self.localizedNames = localizedNames

    def readProducts(self, productsXmlFilename):
    	xmlProductsRoot = ET.parse(productsXmlFilename).getroot()

    	products = list()

    	for xmlRegionAsProduct in xmlProductsRoot.findall("./regionAsProduct"):
    		regionId = xmlRegionAsProduct.get("regionId")
    		priceTier = int(xmlRegionAsProduct.get("priceTier"))
    		name = xmlRegionAsProduct.get("name")
    		localizedNames = dict()

    		for localizedName in xmlRegionAsProduct.findall("localizedName"):
    			localizedNames[localizedName.get("lang")] = localizedName.get("name")

    		products.append(self.RegionAsProduct(regionId, priceTier, name, localizedNames))

    	return products

    # ---------------------------------------------------------------------------------------------------------------------------------------------------------
    def insertInAppPurchaseProducts(self, applicationSKU, metadata, products):
    	xmlMetadataRoot = ET.fromstring(metadata)

    	xmlProducts = xmlMetadataRoot.find(
    		"./{http://apple.com/itunes/importer}software" +
    		"/{http://apple.com/itunes/importer}software_metadata" +
    		"/{http://apple.com/itunes/importer}in_app_purchases");
    	if xmlProducts == None:
    		xmlProducts = ET.Element("{http://apple.com/itunes/importer}in_app_purchases")
    		xmlMetadataRoot.find(
    		"./{http://apple.com/itunes/importer}software" +
    		"/{http://apple.com/itunes/importer}software_metadata").append(xmlProducts)

    	productCounter = 0
    	for product in products:
    		xmlProduct = ET.Element("{http://apple.com/itunes/importer}in_app_purchase")

    		if isinstance(product, self.RegionAsProduct):
    			if product.priceTier == 0:
    				continue

    			xmlProductId = ET.Element("{http://apple.com/itunes/importer}product_id")
    			xmlProductId.text = applicationSKU.replace(".app", ".region.") + product.regionId.replace("_", ".").replace("-", "_")
    			xmlProduct.append(xmlProductId)

    			xmlReferenceName = ET.Element("{http://apple.com/itunes/importer}reference_name")
    			xmlReferenceName.text = "region:" + product.regionId
    			xmlProduct.append(xmlReferenceName)

    			xmlType = ET.Element("{http://apple.com/itunes/importer}type")
    			xmlType.text = "non-consumable"
    			xmlProduct.append(xmlType)

    			xmlPrices = ET.Element("{http://apple.com/itunes/importer}products")
    			xmlPrice = ET.Element("{http://apple.com/itunes/importer}product")
    			xmlPriceEnable = ET.Element("{http://apple.com/itunes/importer}cleared_for_sale")
    			xmlPriceEnable.text = "true"
    			xmlPrice.append(xmlPriceEnable)
    			xmlPriceIntervals = ET.Element("{http://apple.com/itunes/importer}intervals")
    			xmlPriceInterval = ET.Element("{http://apple.com/itunes/importer}interval")
    			xmlPriceIntervalStartDate = ET.Element("{http://apple.com/itunes/importer}start_date")
    			xmlPriceIntervalStartDate.text = time.strftime("%Y-%m-%d")
    			xmlPriceInterval.append(xmlPriceIntervalStartDate)
    			xmlPriceIntervalTier = ET.Element("{http://apple.com/itunes/importer}wholesale_price_tier")
    			xmlPriceIntervalTier.text = str(self.priceTiers[product.priceTier])
    			xmlPriceInterval.append(xmlPriceIntervalTier)
    			xmlPriceIntervals.append(xmlPriceInterval)
    			xmlPrice.append(xmlPriceIntervals)
    			xmlPrices.append(xmlPrice)
    			xmlProduct.append(xmlPrices)

    			xmlReviewNotes = ET.Element("{http://apple.com/itunes/importer}review_notes")
    			xmlReviewNotes.text = (
    				"This product identifies detailed map of specified region. "
    				"Content of map itself is downloaded from OsmAnd internal servers. "
    				"There's no speicific screenshot of the map, so an screenshot of region overview map is attached.")
    			xmlProduct.append(xmlReviewNotes)

    			# Complete fake for now
    			screenshotFilename = os.path.abspath(tempfile.gettempdir() + "/" + applicationSKU + ".itmsp/" + product.regionId + ".png")
    			shutil.copy("empty.png", screenshotFilename)

    			xmlReviewScreenshot = ET.Element("{http://apple.com/itunes/importer}review_screenshot")
    			xmlReviewScreenshotSize = ET.Element("{http://apple.com/itunes/importer}size")
    			xmlReviewScreenshotSize.text = str(os.path.getsize(screenshotFilename))
    			xmlReviewScreenshot.append(xmlReviewScreenshotSize)
    			xmlReviewScreenshotFilename = ET.Element("{http://apple.com/itunes/importer}file_name")
    			xmlReviewScreenshotFilename.text = product.regionId + ".png"
    			xmlReviewScreenshot.append(xmlReviewScreenshotFilename)
    			xmlReviewScreenshotCrc = ET.Element("{http://apple.com/itunes/importer}checksum", type="md5")
    			xmlReviewScreenshotCrc.text = hashlib.md5(open(screenshotFilename, "rb").read()).hexdigest()
    			xmlReviewScreenshot.append(xmlReviewScreenshotCrc)
    			xmlProduct.append(xmlReviewScreenshot)

    			langEnSet = False
    			getLangOnlyRegex = re.compile(r"^[^.]*")
    			xmlProductLocales = ET.Element("{http://apple.com/itunes/importer}locales")
    			for lang, name in product.localizedNames.items():
    				xmlProductLocale = ET.Element("{http://apple.com/itunes/importer}locale")
    				
    				# Seems that iTMSTransporter has issue counting bytes instead of characters
    				if len(name.encode("utf-8")) > 75:
    					continue

    				properLang = re.search(getLangOnlyRegex, locale.normalize(lang)).group(0).replace("_", "-")
    				if properLang not in self.allowedLanguages:
    					continue

    				if lang == "en":
    					langEnSet = True

    				xmlProductLocale.set("name", properLang)

    				xmlTitle = ET.Element("{http://apple.com/itunes/importer}title")
    				xmlTitle.text = name[:(75-3)] + "..." if len(name) > 75 else name
    				xmlProductLocale.append(xmlTitle)

    				xmlDescription = ET.Element("{http://apple.com/itunes/importer}description")
    				xmlDescription.text = name + " (OsmAnd)"
    				xmlProductLocale.append(xmlDescription)

    				xmlProductLocales.append(xmlProductLocale)
    			if not langEnSet:
    				xmlProductLocale = ET.Element("{http://apple.com/itunes/importer}locale")

    				xmlProductLocale.set("name", "en-US")
    				
    				properName = product.name
    				if not properName:
    					properName = product.regionId

    				# Seems that iTMSTransporter has issue counting bytes instead of characters
    				if len(properName.encode("utf-8")) > 75:
    					continue

    				xmlTitle = ET.Element("{http://apple.com/itunes/importer}title")
    				xmlTitle.text = properName[:(75-3)] + "..." if len(properName) > 75 else properName
    				xmlProductLocale.append(xmlTitle)

    				xmlDescription = ET.Element("{http://apple.com/itunes/importer}description")
    				xmlDescription.text = properName + " (OsmAnd)"
    				xmlProductLocale.append(xmlDescription)

    				xmlProductLocales.append(xmlProductLocale)
    			xmlProduct.append(xmlProductLocales)

    		xmlProducts.append(ET.Comment("Product #" + str(productCounter)))
    		xmlProducts.append(xmlProduct)
    		productCounter += 1

    	return '<?xml version="1.0" encoding="UTF-8"?>\n' + ET.tostring(xmlMetadataRoot, encoding="utf-8").decode("utf-8")

# =============================================================================================================================================================
# =============================================================================================================================================================
# =============================================================================================================================================================

if __name__=='__main__':
	# Locate iTMSTransporter binary
	xcodePath = subprocess.check_output(["xcode-select", "--print-path"], universal_newlines=True)
	iTMSTransporterExecutablePath = os.path.abspath(xcodePath + "/../Applications/Application Loader.app/Contents/MacOS/itms/bin/iTMSTransporter")
	if not os.path.isfile(iTMSTransporterExecutablePath):
		print("iTMSTransporter executable not found at '%s'" % (iTMSTransporterExecutablePath))
		sys.exit(-1)

	# Verify iTMSTransporter
	iTMSTransporterVersion = subprocess.check_output([iTMSTransporterExecutablePath, "-version"], universal_newlines=True)
	#print("%s" % (iTMSTransporterVersion))

	# Declare arguments and help
	argumentsDeclaration = argparse.ArgumentParser(
		description="OsmAnd for iOS tool to synchronize provided products.xml with application on iTunes Connect")
	argumentsDeclaration.add_argument("--products",
		dest="productsXmlFilename",
		required=True)
	argumentsDeclaration.add_argument("--applicationSKU",
		dest="applicationSKU",
		required=True)
	argumentsDeclaration.add_argument("--appleId",
		dest="appleId")
	argumentsDeclaration.add_argument("--password",
		dest="password")

	# Parse arguments
	arguments = argumentsDeclaration.parse_args()

	# Ask for Apple ID and/or password if not specified
	if not hasattr(arguments, "appleId") or getattr(arguments, "appleId") == None:
		appleId = input('Apple ID: ')
		setattr(arguments, "appleId", appleId)
	if not hasattr(arguments, "password") or getattr(arguments, "password") == None:
		password = getpass.getpass("Password: ")
		setattr(arguments, "password", password)

	productsSynchronizer = ProductsSynchronizer(iTMSTransporterExecutablePath)
	sys.exit(0 if productsSynchronizer.synchronize(
		arguments.productsXmlFilename,
		arguments.applicationSKU,
		arguments.appleId,
		arguments.password) else -1)
