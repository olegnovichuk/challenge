public with sharing class SuperheroMissionTriggerHandler {

    public void onAfterInsert(List<Superhero_Mission__c> newSuperheroMissions) {
        Database.executeBatch(new SendMissionNotificationBatch(newSuperheroMissions), 200);
    }
}