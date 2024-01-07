({
    getMissions: function (cmp) {
        let action = cmp.get("c.getMissions");
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let listViewResult = response.getReturnValue();
                if(listViewResult.length > 0){
                    cmp.set("v.listViewResult",listViewResult);
                }            }
            else if (state === "INCOMPLETE") {
            }
            else if (state === "ERROR") {
                let errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                            errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    },
});