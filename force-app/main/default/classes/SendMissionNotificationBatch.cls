public with sharing class SendMissionNotificationBatch implements Database.Batchable<SObject>, Database.Stateful {
    List<Superhero_Mission__c> missions = new List<Superhero_Mission__c>();
    Map<Id, Set<Hero__c>> heroesByMissionId = new Map<Id, Set<Hero__c>>();

    public SendMissionNotificationBatch(List<Superhero_Mission__c> missions){
        this.missions = missions;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = '';
        Set<Id> guildIds = new Set<Id>();
        for (Superhero_Mission__c mission : missions) {
            if (mission.Is_Public__c) {
                query = 'SELECT Id, Name, Contact__c FROM Hero__c';
                break;
            } else {
                guildIds.add(mission.Guild__c);
            }
        }

        if (String.isBlank(query)) {
            query = 'SELECT Id, Name, Contact__c, Guild__c FROM Hero__c WHERE Guild__c IN :guildIds';
        }

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        for (Superhero_Mission__c mission : missions) {
            Set<Hero__c> availableHeroes = heroesByMissionId.containsKey(mission.Id)
                ? heroesByMissionId.get(mission.Id)
                : new Set<Hero__c>();

            if (mission.Is_Public__c) {
                availableHeroes.addAll((List<Hero__c>) scope);
            } else {
                for (Hero__c hero : (List<Hero__c>) scope) {
                    if (hero.Guild__c == mission.Guild__c) {
                        availableHeroes.add(hero);
                    }
                }
            }
            heroesByMissionId.put(mission.Id, availableHeroes);
        }
    }

    public void finish(Database.BatchableContext bc) {
        Site site = [SELECT Id FROM Site WHERE Name = 'Challenge'];
        SiteDetail siteDetail = [SELECT SecureUrl FROM SiteDetail WHERE DurableId = :site.Id];

        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        for (Superhero_Mission__c mission : missions) {
            if (!heroesByMissionId.containsKey(mission.Id)) {
                continue;
            }
            for (Hero__c hero : heroesByMissionId.get(mission.Id)) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                String body = 'Hi, hero ' + hero.Name + '. New Mission ' + mission.Subject__c + ' available. You can find it in ' + siteDetail.SecureUrl;
                mail.setSubject('New Mission available');
                mail.setTargetObjectId(hero.Contact__c);
                mail.setSaveAsActivity(false);
                mail.setHtmlBody(body);
                mails.add(mail);
            }
        }

        try {
            if(!Test.isRunningTest() && mails != null && mails.size() > 0) {
                Messaging.sendEmail(mails);
            }
        } catch (Exception e) {
            System.debug(e);
        }
    }
}