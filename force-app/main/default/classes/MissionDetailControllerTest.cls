@IsTest
private class MissionDetailControllerTest {

    @TestSetup
    static void testSetup(){
        Account account = new Account(Name = 'Test Acc');
        insert account;

        Contact contact = new Contact(LastName = 'Test', AccountId = account.Id);
        insert contact;

        Profile customerProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community user' LIMIT 1];
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        User adminUser = new User(
            Username = 'test_' + Math.random() + '@test.com',
            LastName = 'Test-Admin',
            Alias = 'adm',
            Email = 'test' + Math.random() + '@test.com',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = adminProfile.Id
        );
        insert adminUser;

        User customerUser = new User(
            Username = 'test_' + Math.random() + '@test.com',
            LastName = 'Test-Last',
            Alias = 'test',
            Email = 'test' + Math.random() + '@test.com',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = customerProfile.Id,
            ContactId = contact.Id
        );
        insert customerUser;

        System.runAs(adminUser){
            PermissionSet permissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'Hero_User'];
            PermissionSetAssignment psa = new PermissionSetAssignment();
            psa.AssigneeId = customerUser.Id;
            psa.PermissionSetId = permissionSet.Id;
            insert psa;
        }

        Guild__c guild = new Guild__c(Name = 'Test guild');
        insert guild;

        Hero__c hero = new Hero__c(
            Name = 'TestHero',
            Contact__c = contact.Id,
            Guild__c = guild.Id,
            Rank__c = 'A'
        );
        insert hero;

        Superhero_Mission__c mission = new Superhero_Mission__c(
            Subject__c = 'TestMission',
            Guild__c = guild.Id,
            Complexity_Rank__c = 'A',
            Details__c = 'test'
        );
        insert mission;
    }

    @IsTest
    static void getMissionDetailsTest() {
        User user = [SELECT Id, ContactId FROM User WHERE LastName = 'Test-Last'];
        Superhero_Mission__c mission = [SELECT Id FROM Superhero_Mission__c WHERE Subject__c = 'TestMission'];

        System.runAs(user){
            mission = MissionDetailController.getMissionDetails(mission.Id);
        }
        System.assertEquals('A', mission.Complexity_Rank__c);
    }

    @IsTest
    static void assignMissionTest() {
        User user = [SELECT Id, ContactId FROM User WHERE LastName = 'Test-Last'];
        Superhero_Mission__c mission = [SELECT Id FROM Superhero_Mission__c WHERE Subject__c = 'TestMission'];

        System.runAs(user){
            MissionDetailController.assignMission(mission.Id);
        }
        List<Mission_Assignment__c> missionAssignments = [SELECT Id FROM Mission_Assignment__c WHERE Mission__c = :mission.Id];

        System.assertEquals(1, missionAssignments.size());
    }

    @IsTest
    static void completeMissionTest() {
        User user = [SELECT Id, ContactId FROM User WHERE LastName = 'Test-Last'];
        Superhero_Mission__c mission = [SELECT Id FROM Superhero_Mission__c WHERE Subject__c = 'TestMission'];
        Hero__c hero = [SELECT Id FROM Hero__c WHERE Name = 'TestHero'];

        Mission_Assignment__c missionAssignment = new Mission_Assignment__c(
            Hero__c = hero.Id,
            Mission__c = mission.Id
        );
        insert missionAssignment;

        System.runAs(user){
            MissionDetailController.completeMission(mission.Id);
        }
        System.assertEquals(1, [SELECT Id FROM Mission_Assignment__c WHERE Id = :missionAssignment.Id AND Status__c = 'Completed'].size());
    }
}