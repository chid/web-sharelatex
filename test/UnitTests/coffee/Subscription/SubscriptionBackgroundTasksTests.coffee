sinon = require('sinon')
require('chai').should()
SandboxedModule = require('sandboxed-module')
modulePath = require('path').join __dirname, '../../../../app/js/Features/Subscription/SubscriptionBackgroundTasks'

describe "SubscriptionBackgroundTasks", ->
	beforeEach ->
		@SubscriptionLocator = {}
		@Settings = defaultPlanCode:
			collaborators: 13
			versioning: true
		@AnalyticsManager = {}
		@SubscriptionUpdater = {}

		@SubscriptionBackgroundTasks = SandboxedModule.require modulePath, requires:
			"./SubscriptionLocator"         : @SubscriptionLocator
			"./SubscriptionUpdater"			: @SubscriptionUpdater
			"settings-sharelatex"           : @Settings
			"../Analytics/AnalyticsManager" : @AnalyticsManager
			"logger-sharelatex"				: log:->

	describe 'downgradeExpiredFreeTrials', ->
		beforeEach ->
			@subscriptions = [
				{ admin_id : 1 },
				{ admin_id : 2 }
			]
			@SubscriptionUpdater.downgradeFreeTrial = sinon.stub().callsArg(1)
			@SubscriptionLocator.expiredFreeTrials = sinon.stub().callsArgWith(0, null, @subscriptions)
			@AnalyticsManager.trackFreeTrialExpired = sinon.stub()
			@callback = sinon.stub()
			@SubscriptionBackgroundTasks.downgradeExpiredFreeTrials(@callback)

		it "should downgrade each expired subscription", ->
			@SubscriptionUpdater.downgradeFreeTrial.callCount.should.equal @subscriptions.length
			for subscription in @subscriptions
				@SubscriptionUpdater.downgradeFreeTrial.calledWith(subscription).should.equal true

		it "should track each downgrade", ->
			@AnalyticsManager.trackFreeTrialExpired.callCount.should.equal @subscriptions.length
			for subscription in @subscriptions
				@AnalyticsManager.trackFreeTrialExpired.calledWith(subscription.admin_id).should.equal true

		it "should return the subscriptions in the callback", ->
			@callback.called.should.equal true
			@callback.args[0][1].should.deep.equal @subscriptions
