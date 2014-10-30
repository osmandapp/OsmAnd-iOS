#!/usr/bin/python
# -*- coding: utf-8 -*

import sys
import os
import getpass
import urllib.request, urllib.parse
import http.cookiejar
import html.parser

# =============================================================================================================================================================
# =============================================================================================================================================================
# =============================================================================================================================================================

class TestflightJanitor(object):
    # ---------------------------------------------------------------------------------------------------------------------------------------------------------
    def __init__(self):
    	self.cookiesJar = http.cookiejar.CookieJar()
    	self.cookiesHandler = urllib.request.HTTPCookieProcessor(self.cookiesJar)
    	self.redirectHandler = urllib.request.HTTPRedirectHandler()
    	self.opener = urllib.request.build_opener(self.cookiesHandler, self.redirectHandler)

    # ---------------------------------------------------------------------------------------------------------------------------------------------------------
    def dumpCookies(self):
    	for cookie in self.cookiesJar:
    		print(cookie.name + "=" + cookie.value)

    # ---------------------------------------------------------------------------------------------------------------------------------------------------------
    def getSession(self):
    	request = urllib.request.Request("https://www.testflightapp.com/login/")
    	response = self.opener.open(request);

    # ---------------------------------------------------------------------------------------------------------------------------------------------------------
    def login(self, username, password):
    	self.getSession()
    	data = {
    		"csrfmiddlewaretoken" : next(cookie.value for cookie in self.cookiesJar if cookie.name == "csrftoken"),
    		"username" : username,
    		"password" : password
    	}
    	postData = urllib.parse.urlencode(data).encode('ascii')
    	request = urllib.request.Request("https://www.testflightapp.com/login/", postData, {}, "www.testflightapp.com/login/")
    	response = self.opener.open(request);
    	return True

    # ---------------------------------------------------------------------------------------------------------------------------------------------------------
    class PagesCollectionParser(html.parser.HTMLParser):
    	def __init__(self):
    		super().__init__()
    		self.maxPageNumber = 0
    		self.prefix = "/dashboard/applications/750280/builds/?page="

    	def handle_starttag(self, tag, attrs):
    		if tag != "a":
    			return
    		for k, v in attrs:
    			if k != "href" or not v.startswith(self.prefix):
    				continue
    			self.maxPageNumber = max(self.maxPageNumber, int(v[len(self.prefix):]))

    	def handle_endtag(self, tag):
    		return

    	def handle_data(self, data):
    		return

    def getBuilds(self, appId):
    	request = urllib.request.Request("https://www.testflightapp.com/dashboard/applications/%d/builds/" % (appId))
    	response = self.opener.open(request);
    	htmlContent = response.read().decode('ascii')
    	parser = self.PagesCollectionParser()
    	parser.feed(htmlContent)
    	print("Found %d pages with builds" % (parser.maxPageNumber))
    	builds = []
    	for pageIndex in range(parser.maxPageNumber):
    		buildsOnPage = self.getBuildsFromPage(appId, pageIndex)
    		builds = builds + buildsOnPage
    	return builds

    # ---------------------------------------------------------------------------------------------------------------------------------------------------------
    class BuildsOnPageParser(html.parser.HTMLParser):
    	def __init__(self):
    		super().__init__()
    		self.builds = []
    		self.prefix = "/dashboard/builds/crashes/"

    	def handle_starttag(self, tag, attrs):
    		if tag != "a":
    			return
    		for k, v in attrs:
    			if k != "href" or not v.startswith(self.prefix):
    				continue
    			self.builds.append(int(v[len(self.prefix):]))

    	def handle_endtag(self, tag):
    		return

    	def handle_data(self, data):
    		return

    def getBuildsFromPage(self, appId, pageIndex):
    	request = urllib.request.Request("https://www.testflightapp.com/dashboard/applications/%d/builds/?page=%d" % (appId, pageIndex + 1))
    	response = self.opener.open(request);
    	htmlContent = response.read().decode('ascii')
    	parser = self.BuildsOnPageParser()
    	parser.feed(htmlContent)
    	print("Found %d builds on page %d" % (len(parser.builds), pageIndex + 1))
    	return parser.builds

    # ---------------------------------------------------------------------------------------------------------------------------------------------------------
    def deleteBuild(self, buildId):
    	print("Deleting build #%d..." % (buildId))
    	page = "https://www.testflightapp.com/dashboard/builds/delete/%d/" % (buildId)
    	data = {
    		"csrfmiddlewaretoken" : next(cookie.value for cookie in self.cookiesJar if cookie.name == "csrftoken")
    	}
    	postData = urllib.parse.urlencode(data).encode('ascii')
    	request = urllib.request.Request(page, postData, {}, page)
    	response = self.opener.open(request);

    # ---------------------------------------------------------------------------------------------------------------------------------------------------------
    def cleanup(self, username, password, appId, buildsToKeep):
    	ok = self.login(username, password)
    	if ok == False:
    		return False
    	builds = self.getBuilds(appId)
    	buildsToDelete = builds[buildsToKeep:]
    	print("Going to delete oldest %d builds from %d..." % (len(buildsToDelete), len(builds)))
    	for buildId in buildsToDelete:
    		self.deleteBuild(buildId)
    	return True

# =============================================================================================================================================================
# =============================================================================================================================================================
# =============================================================================================================================================================

if __name__=='__main__':
	username = input('Username: ')
	password = getpass.getpass("Password: ")
	appId = int(input("Application ID: "))
	buildsToKeep = int(input("Number of builds to keep: "))

	janitor = TestflightJanitor()
	sys.exit(0 if janitor.cleanup(username, password, appId, buildsToKeep) else -1)
