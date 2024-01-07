import { LightningElement, wire, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent} from 'c/pubsub';
import missionCommunication from '@salesforce/messageChannel/missionCommunication__c';
import getMissionDetails from '@salesforce/apex/MissionDetailController.getMissionDetails';
import assignMission from '@salesforce/apex/MissionDetailController.assignMission';
import completeMission from '@salesforce/apex/MissionDetailController.completeMission';

export default class MissionDetail extends LightningElement {
    @api emptyLabel = '';
    subscription = null;

    recordId;
    showData = false;
    mission;
    isAssigned = false;
    isDisabledButton = true;

    @wire(MessageContext)
    messageContext;
    @wire(CurrentPageReference)
    pageRef;

    connectedCallback() {
        this.subscribeToMessageChannel();

    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                missionCommunication,
                (message) => this.handleMessage(message),
                {scope: APPLICATION_SCOPE}
            );
        }
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    handleMessage(message) {
        this.recordId = message.recordId;
        this.getDetails();

    }

    handleAccept() {
        this.isDisabledButton = true;
        assignMission({ missionId: this.recordId })
            .then(result => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Mission Assigned',
                        message: this.mission.Subject__c,
                        variant: 'success',
                    })
                );
                this.isAssigned = true;
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error',
                    })
                );
                console.error('Error', JSON.stringify(error));
            })
            .finally( () => {
                this.isDisabledButton = false;
            });
    }

    handleComplete() {
        this.isDisabledButton = true;
        completeMission({ missionId: this.recordId })
            .then(result => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Mission Completed',
                        message: this.mission.Subject__c,
                        variant: 'success',
                    })
                );
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error',
                    })
                );
                console.error('Error', JSON.stringify(error));
            })
            .finally( () => {
                fireEvent(this.pageRef ,'reload');
                this.isDisabledButton = true;
            });
    }

    getDetails() {
        getMissionDetails({ missionId: this.recordId })
            .then(result => {
                this.mission = result;
                this.showData = true;
                this.isAssigned = this.mission.Status__c === 'Completed'
                    ? true
                    : (this.mission.Mission_Assignments__r) ? true : false;
                this.isDisabledButton = this.mission.Status__c === 'Completed';
                this.mission.Reward__c = (this.mission.Reward__c) ? this.mission.Reward__c : 0;
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Something went wrong',
                        variant: 'error',
                    })
                );
                console.error('Error', JSON.stringify(error));
            });
    }
}