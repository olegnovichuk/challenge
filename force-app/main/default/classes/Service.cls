public with sharing class Service {
    public static final String COMPLETED_STATUS = 'Completed';
    public static final String IN_PROGRESS_STATUS = 'In Progress';

    public static final Map<String, Integer> RANK_MAP = new Map<String, Integer>{
        'S' => 1,
        'A' => 2,
        'B' => 3,
        'C' => 4,
        'D' => 5
    };

    public static Hero__c currentHero {
        get {
            if (currentHero == null) {
                Contact userContact = [SELECT Id FROM Contact WHERE Id IN (SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId())];
                System.debug(userContact);
                currentHero = [SELECT Id, Guild__c, Rank__c FROM Hero__c WHERE Contact__c = :userContact.Id];
            }

            return currentHero;
        }
        private set;
    }

}