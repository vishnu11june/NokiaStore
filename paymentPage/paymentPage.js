import { LightningElement, api} from 'lwc';
import startPayment from '@salesforce/apex/StripePaymentGateWay.startPayment';
import setData from '@salesforce/apex/StripePaymentGateWay.setData';
import cards from '@salesforce/resourceUrl/cards';
import payment from '@salesforce/resourceUrl/payment';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PaymentPage extends LightningElement {
    @api cartId;
    @api orderId;
    nameFieldRegex = '^[A-Za-z ]+$';
    nameRegex = new RegExp(/^[A-Za-z ]+$/);
    credCardregex = new RegExp(/^(?:(4[0-9]{12}(?:[0-9]{3})?)|(5[1-5][0-9]{14})|(3[47][0-9]{13}))/);
    cvvRegex = new RegExp(/^[0-9]{3,4}$/);
    value;
    selectedMonth = '';
    newMonths =[];
    selectedYear = '';
    cardExpiryYears = [];
    cardDigits = '';
    CVC = '';
    nameOnCard = '';
    GrandTotal = '';
    BillingAddress = [];
    selectedBillingAddress = '';
    ConsumerName;
    ConsumerEmail;
    ConsumerPhone;
    visaCard = cards + '/visa.svg';
    masterCard = cards + '/cc-mastercard-brands.svg';
    amexCard = cards + '/cc-amex-brands.svg';
    paymentMsg = payment + '/payment.gif';
    _title;
    message;
    variant;
    currCredCard;
    connectedCallback(){
        
        setData({cartId:this.cartId}).then(result => {
            this.BillingAddress = result;
            console.log('cartId : ',this.cartId);
            console.log('OrderId : ',this.orderId);
            console.log('BillingAddress : ',this.BillingAddress);
            this.GrandTotal = this.BillingAddress[this.BillingAddress.length - 1].value;
            this.GrandTotal = parseFloat(this.GrandTotal);
            this.GrandTotal = this.GrandTotal.toFixed(2);
            this.GrandTotal = this.GrandTotal.toString();
            this.ConsumerName = this.BillingAddress[this.BillingAddress.length - 4].value;
            this.ConsumerEmail = this.BillingAddress[this.BillingAddress.length - 3].value;
            this.ConsumerPhone = this.BillingAddress[this.BillingAddress.length - 2].value;
            console.log(this.ConsumerName,' : ',this.ConsumerEmail,' | ',this.ConsumerPhone);
            this.BillingAddress =  this.BillingAddress.slice(0, -4);
            console.log('GrandTotal : ',this.GrandTotal);
            
        }).catch(error => {
            console.log('Error : ',error);
        });
   } 
    get BillingAddressInfo(){
        return this.BillingAddress;
    }
    get options() {
        return [
            { label: 'Visa', value: 'Visa' },
            { label: 'MasterCard', value: 'MasterCard' },
            { label: 'AmericanExpress', value: 'AmericanExpress' },
            { label: 'DinnersClub', value: 'DinnersClub' },
            { label: 'JCB', value: 'JCB' },
        ];
    }
    get cardExpMonths() {
        
        for (let i = 1; i <= 12; i++) {
            var newMonth = {};
            newMonth.label = i.toString();
            newMonth.value = i.toString();
            this.newMonths.push(newMonth);
          }
        return this.newMonths;
    }
    get cardExpyear() {
        
        for (let i = 2022; i <= 2030; i++) {
            var newYear = {};
            newYear.label = i.toString();
            newYear.value = i.toString();
            this.cardExpiryYears.push(newYear);
          }
        return this.cardExpiryYears;
    }
    handleChange(event) {
        this.value = event.detail.value;
    }
    onMonthChange(event){
        this.selectedMonth = event.detail.value;
    }
    onYearChange(event){
        this.selectedYear = event.detail.value;
    }
    cardNumber(event){
            this.cardDigits = event.detail.value;
            let firstDigit = this.cardDigits.charAt(0);
            if(firstDigit == '4'){
                this.currCredCard = this.visaCard;
            }else if(firstDigit == '5'){
                this.currCredCard = this.masterCard;
            }else if(firstDigit == '3'){
                this.currCredCard = this.amexCard;
            }
            
    }
    CVCNumber(event){
        this.CVC = event.detail.value;
    }
    customerName(event){
        this.nameOnCard = event.detail.value;
        this.nameOnCard = this.nameOnCard.trim();
    }
    setBillingAddress(event){
        this.selectedBillingAddress = event.detail.value;
    }
    paymentInfo(event){
        try{
            if(this.nameRegex.test(this.nameOnCard) && this.nameOnCard != ''){
                if(this.credCardregex.test(this.cardDigits) &&  this.cardDigits != ''){
                    if(this.cvvRegex.test(this.CVC) && this.CVC != ''){
                        if(this.selectedMonth != ''){
                            if(this.selectedYear != ''){
                                if(this.selectedBillingAddress != ''){
                                    console.log('all cases passed');
                                }else{
                                   
                                    this._title = 'Billing address';
                                    this.message = 'Kindly choose the billing';
                                    this.variant = 'error';
                                    this.showError();
                                }
                            }else{
                                
                                this._title = 'Credit card expiry year';
                                this.message = 'Kindly choose the credit card expiry year';
                                this.variant = 'error';
                                this.showError();
                            }
                        }else{
                            
                            this._title = 'Credit card expiry month';
                            this.message = 'Kindly choose the credit card expiry month';
                            this.variant = 'error';
                            this.showError();
                        }
                    }else{
                        
                        this._title = 'Card CVV';
                        this.message = 'Invalid cvv number or required field missing';
                        this.variant = 'error';
                        this.showError();
                    }
                }else{
                    
                    this._title = 'Credit card';
                    this.message = 'Invalid credit card number or required field missing';
                    this.variant = 'error';
                    this.showError();
                }                
            }else{
                this._title = 'Name on card';
                this.message = 'Invalid name or required field missing';
                this.variant = 'error';
                this.showError();
            }     
            
           
        }catch(Err){
            console.log(Err);
        }
       
        // startPayment({cartId:this.cartId,cardNumber:this.cardDigits,CVV:this.CVC,exp_Month:this.selectedMonth,exp_Year:this.selectedYear,card:'card',nameOnCard:this.nameOnCard,consumerName:this.ConsumerName,consumerEmail:this.ConsumerEmail,totalAmount:this.GrandTotal}).then(result => {
        //     console.log('info : ',result);
        // }).catch(error => {
        //     console.log('Error : ',error);
        // });
        // var divblock = this.template.querySelector('[data-id="pmtCmp"]');
        // if(divblock){
        //     this.template.querySelector('[data-id="pmtCmp"]').className='displayNone';
        // }
        // var divblock = this.template.querySelector('[data-id="showToast"]');
        // if(divblock){
        //     this.template.querySelector('[data-id="showToast"]').className='displayConfirm';
        // }
    }
    showError() {
        const evt = new ShowToastEvent({
            title: this._title,
            message: this.message,
            variant: this.variant,
        });
        this.dispatchEvent(evt);
    }
}