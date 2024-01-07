public without sharing class CompleteMissionBatch implements Database.Batchable<SObject>, Database.Stateful {
    static final String COMPLETED_STATUS = 'Completed';
    static final String FAILED_STATUS = 'Failed';

    List<Mission_Assignment__c> missionAssignments = new List<Mission_Assignment__c>();
    List<Id> missionAssignmentIds = new List<Id>();
    List<Superhero_Mission__c> missions = new List<Superhero_Mission__c>();

    public CompleteMissionBatch(List<Mission_Assignment__c> missionAssignments){
        this.missionAssignments = missionAssignments;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Set<Id> missionIds = new Set<Id>();
        for (Mission_Assignment__c missionAssignment : missionAssignments) {
            missionAssignmentIds.add(missionAssignment.Id);
            missionIds.add(missionAssignment.Mission__c);
        }
        if (!missionIds.isEmpty()) {
            missions = [SELECT Id, OwnerId, Subject__c, Owner.Name FROM Superhero_Mission__c WHERE Id IN :missionIds];
        }

        String query = 'SELECT Id, Status__c, Mission__c FROM Mission_Assignment__c WHERE Mission__c IN :missionIds';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Mission_Assignment__c> missionAssignmentsForUpdate = new List<Mission_Assignment__c>();
        for (Mission_Assignment__c missionAssignment : (List<Mission_Assignment__c>) scope) {
            missionAssignment.Status__c = missionAssignmentIds.contains(missionAssignment.Id) ? COMPLETED_STATUS : FAILED_STATUS;
            missionAssignmentsForUpdate.add(missionAssignment);
        }

        try {
            update missionAssignmentsForUpdate;
        } catch (Exception e) {
            System.debug(e);
        }
    }

    public void finish(Database.BatchableContext bc) {
        String base = Network.getLoginUrl(Network.getNetworkId());

        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        for (Superhero_Mission__c mission : missions) {
            mission.Status__c = COMPLETED_STATUS;

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String body = 'Hi, ' + mission.Owner.Name + '. Mission ' + base + '/' + mission.Id + ' Completed';
            mail.setSubject('Mission ' + mission.Subject__c + ' Completed');
            mail.setTargetObjectId(mission.OwnerId);
            mail.setSaveAsActivity(false);
            mail.setHtmlBody(body);
            mails.add(mail);
        }
        try {
            update missions;
            if(!Test.isRunningTest() && mails != null && mails.size() > 0) {
                Messaging.sendEmail(mails);
            }
        } catch (Exception e) {
            System.debug(e);
        }
    }
}