public with sharing class MissionDetailController {

    @AuraEnabled(Cacheable=false)
    public static Superhero_Mission__c getMissionDetails(String missionId) {
        return new WithoutSharing().getMissionDetails(missionId);
    }

    @AuraEnabled(Cacheable=false)
    public static void assignMission(String missionId) {
        new WithoutSharing().assignMission(missionId);
    }

    @AuraEnabled(Cacheable=false)
    public static void completeMission(String missionId) {
        new WithoutSharing().completeMission(missionId);
    }

    private static void validateAssign(String missionId) {
        Superhero_Mission__c mission = new WithoutSharing().getMissionDetails(missionId);
        if (mission.Status__c == Service.COMPLETED_STATUS) {
            throw new MissionException('Миссия уже закончена');
        }

        if (!mission.Mission_Assignments__r.isEmpty()) {
            throw new MissionException('Миссия уже была выбрана');
        }

        Integer heroRank = Service.RANK_MAP.get(Service.currentHero.Rank__c);
        Integer missionRank = Service.RANK_MAP.get(mission.Complexity_Rank__c);
        if (heroRank != missionRank && heroRank != missionRank - 1 && heroRank != missionRank + 1) {
            throw new MissionException(
                'К сожалению вы слишком слабый на данный момент чтобы взяться за эту работку! ' +
                'Возвращайтесь когда достигните ранга ' + mission.Complexity_Rank__c
            );
        }

        List<Mission_Assignment__c> missionAssignments = [
            SELECT Id FROM Mission_Assignment__c
            WHERE Hero__c = :Service.currentHero.Id
                AND Status__c = :Service.IN_PROGRESS_STATUS
            LIMIT 3
        ];
        if (missionAssignments.size() == 3) {
            throw new MissionException('Можно иметь максимум 3 активных задания');
        }
    }

    private static void validateComplete(String missionId) {
        Superhero_Mission__c mission = new WithoutSharing().getMissionDetails(missionId);
        if (mission.Status__c == Service.COMPLETED_STATUS) {
            throw new MissionException('Миссия уже закончена кем-то другим');
        }
    }

    private without sharing class WithoutSharing {

        public Superhero_Mission__c getMissionDetails(String missionId) {
            Superhero_Mission__c mission = [
                SELECT Id, Subject__c, Reward__c, Deadline__c, Details__c, Is_Public__c, Guild__r.Name, Status__c, Complexity_Rank__c,
                (SELECT Id FROM Mission_Assignments__r WHERE Hero__c = :Service.currentHero.Id)
                FROM Superhero_Mission__c WHERE Id = :missionId LIMIT 1
            ];

            return mission;
        }

        public void assignMission(String missionId) {
            try {
                validateAssign(missionId);
                insert new Mission_Assignment__c(
                    Hero__c = Service.currentHero.Id,
                    Mission__c = missionId
                );
            } catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
        }


        public void completeMission(String missionId) {
            try {
                validateComplete(missionId);
                List<Mission_Assignment__c> missionAssignments = [
                    SELECT Id, Status__c
                    FROM Mission_Assignment__c
                    WHERE Status__c = :Service.IN_PROGRESS_STATUS
                        AND Hero__c = :Service.currentHero.Id
                        AND Mission__c = :missionId
                ];

                if (!missionAssignments.isEmpty()) {
                    missionAssignments.get(0).Status__c = Service.COMPLETED_STATUS;
                    update missionAssignments.get(0);
                }
            } catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
        }
    }

    public class MissionException extends Exception { }
}