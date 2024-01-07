({
    doInit: function(cmp, event, helper) {
        helper.getMissions(cmp);
    },
    handleClick: function(cmp, event) {
        let recordId = event.currentTarget.dataset.index;
        let message = {
            recordId: recordId,
        };
        cmp.find("missionCommunication").publish(message);
    },
    handleReload: function(cmp, event, helper){
        let pubsub = cmp.find('pubsub');
        pubsub.registerListener('reload', $A.getCallback(function(response) {
            helper.getMissions(cmp);
            $A.get('e.force:refreshView').fire();
        }));
    }
});