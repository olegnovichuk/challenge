@IsTest
private class AllMissionsControllerTest {

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
    static void getMissionsTest() {
        User user = [SELECT Id, ContactId FROM User WHERE LastName = 'Test-Last'];
        List<Superhero_Mission__c> missions = new List<Superhero_Mission__c>();
        System.runAs(user){
            missions.addAll(AllMissionsController.getMissions());
        }
        System.assertEquals(1, missions.size());
    }
}