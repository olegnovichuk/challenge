public with sharing class AllMissionsController {

    @AuraEnabled
    public static List<Superhero_Mission__c> getMissions() {
        return new WithoutSharing().getAvailableMissions();
    }

    private without sharing class WithoutSharing {

        public List<Superhero_Mission__c> getAvailableMissions() {
            List<Superhero_Mission__c> missions = [
                SELECT Id, Subject__c, Reward__c, Deadline__c, Details__c, Is_Public__c, Guild__r.Name, Status__c, Complexity_Rank__c
                FROM Superhero_Mission__c
                WHERE Guild__c = :Service.currentHero.Guild__c OR Is_Public__c = TRUE
                ORDER BY CreatedDate DESC
                LIMIT 10000
            ];
            
            return missions;
        }
    }
}