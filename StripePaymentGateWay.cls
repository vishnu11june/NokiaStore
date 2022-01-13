public with sharing class StripePaymentGateWay {
    @AuraEnabled
    public static List<BillingAddressWrap> setData(String cartId){
        try{
            Decimal totalAmount;
            List<BillingAddressWrap> billAddress = new List<BillingAddressWrap>();
            List<ContactPointAddress> billingAddress = new List<ContactPointAddress>();
            User currentUser = new User();
            System.debug('cartId : '+cartId);
            if(cartId != null && cartId != ''){
                WebCart cartInfo = [SELECT Id, Name, Status, Type, BillingAddress, GrandTotalAmount, AccountId FROM WebCart WHERE Id =: cartId LIMIT 1];
                System.debug('cartInfo : '+cartInfo);
                if(cartInfo != null){
                    totalAmount = cartInfo.GrandTotalAmount;
                    String userId = userInfo.getUserId();
                    System.debug('userId : '+userId);
                    currentUser = [SELECT Id, Name, Email, MobilePhone FROM User WHERE Id = :userId LIMIT 1];
                    billingAddress = [SELECT Id, Name, IsDefault, Address, ParentId, AddressType FROM ContactPointAddress WHERE ParentId =: cartInfo.AccountId AND AddressType = 'Billing'];
                }
                if(billingAddress != null && !billingAddress.isEmpty()){
                    for(ContactPointAddress bAdd : billingAddress){
                        BillingAddressWrap newBillAdd = new BillingAddressWrap();
                        Address completeAddress = bAdd.Address;
                        String tempAddress = completeAddress.city+' '+completeAddress.state+' '+completeAddress.country+' '+completeAddress.postalcode;
                        newBillAdd.label = tempAddress;
                        newBillAdd.value  = tempAddress;
                        billAddress.add(newBillAdd);
                    }
                }
                if(billAddress != null && !billAddress.isEmpty()){
                    BillingAddressWrap customerName = new BillingAddressWrap();
                    customerName.label = 'Name';
                    customerName.value = currentUser.Name;
                    billAddress.add(CustomerName);
                    BillingAddressWrap customerEmail = new BillingAddressWrap();
                    customerEmail.label = 'Email';
                    customerEmail.value = currentUser.Email;
                    billAddress.add(customerEmail);
                    BillingAddressWrap customerPhone = new BillingAddressWrap();
                    customerPhone.label = 'Phone';
                    customerPhone.value = String.valueOf(currentUser.MobilePhone);
                    System.debug('customerPhone.value : '+customerPhone.value);
                    if(customerPhone.value == '' || customerPhone.value == null){
                        customerPhone.value = 'null';
                    }
                    billAddress.add(customerPhone);
                    BillingAddressWrap newBillAdd = new BillingAddressWrap();
                    newBillAdd.label = 'Amount';
                    newBillAdd.value = string.valueOf(totalAmount);
                    billAddress.add(newBillAdd);
                    return billAddress;
                }
            }
        }catch(Exception Err){
            System.debug(LoggingLevel.ERROR, 'Exception Details: Line Number Is : '+Err.getLineNumber()+' | Cause Is : '+Err.getCause()+' | Meassage Is : '+Err.getMessage()+' | Trace Is : '+Err.getStackTraceString());    
        }
        return null;
    }
    @AuraEnabled
    public static String startPayment(String cartId, String cardNumber, String CVV, String exp_Month, String exp_Year, String card, String nameOnCard, String consumerName, String consumerEmail, String totalAmount){
        try{
            
            System.debug('cartId : ' +cartId);
            Boolean checkData = checkNullData(cartId, cardNumber, CVV, exp_Month, exp_Year, card, nameOnCard, consumerName, consumerEmail, totalAmount);
            if(checkData){
                String customerId = createCustomer(consumerName, consumerEmail);
                String paymentMethod = createPaymentMethod(customerId,cardNumber, CVV, exp_Month, exp_Year);
                String new_Prod_Id;
                String new_Price_Id;
                String checkout_Session_Id;
                CartItem productInfo = [SELECT Id, Product2Id, Quantity, Product2.Name FROM CartItem WHERE cartId =:cartId AND Sku != null LIMIT 1];
                System.debug('productInfo : '+productInfo);
           
                Decimal itm_Price = Decimal.valueOf(totalAmount)/productInfo.Quantity;
                itm_Price = itm_Price*100;
                itm_Price = Integer.valueOf(itm_Price);
                if(productInfo != null){
                    new_Prod_Id = createProduct(productInfo.Product2.Name);
                    new_Price_Id = createPrice(itm_Price, new_Prod_Id);
                    checkout_Session_Id = createCheckOutSession(Integer.valueOf(productInfo.Quantity), new_Price_Id, customerId);
                WebCart cartInfo = [SELECT Id FROM WebCart WHERE Id =: cartId LIMIT 1];
                delete cartInfo;
                return checkout_Session_Id;
            }
            }
                        
        }catch(Exception Err){
            System.debug(LoggingLevel.ERROR, 'Exception Details: Line Number Is : '+Err.getLineNumber()+' | Cause Is : '+Err.getCause()+' | Meassage Is : '+Err.getMessage()+' | Trace Is : '+Err.getStackTraceString());    
        }
        return null;
    }
    
    public static String createCustomer(String name, String email){
        try{
            if(name != null && name != '' && email != null && email != ''){
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:My_Named_Credential/v1/customers');
                req.setMethod('POST'); 
                req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
                String customerDetails = 'name='+name+'&email='+email+'&description=Salesforce customer';
                req.setBody(customerDetails);
                Http http = new Http();
                HTTPResponse res = http.send(req);
                System.debug(res.getBody());
                JSONParser parser = JSON.createParser(res.getBody());
                parser.nextToken();
                parser.nextValue();
                String newCustomerId = String.valueof(parser.getText());
                System.debug('newCustomerId : '+newCustomerId);
                return newCustomerId;
            }
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:My_Named_Credential/v1/customers');
            req.setMethod('POST'); 
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            String customerDetails = 'name='+name+'&email='+email+'&description=Salesforce customer';
            req.setBody(customerDetails);
            Http http = new Http();
            HTTPResponse res = http.send(req);
            System.debug(res.getBody());
            JSONParser parser = JSON.createParser(res.getBody());
            parser.nextToken();
            parser.nextValue();
            String newCustomerId = String.valueof(parser.getText());
            System.debug('newCustomerId : '+newCustomerId);
            return newCustomerId;
        }catch(Exception Err){
            System.debug(LoggingLevel.ERROR, 'Exception Details: Line Number Is : '+Err.getLineNumber()+' | Cause Is : '+Err.getCause()+' | Meassage Is : '+Err.getMessage()+' | Trace Is : '+Err.getStackTraceString());
        }
        return null;
    }
    public static String createPaymentMethod(String customerId, String cardNumber, String CVC, String exp_Month, String exp_Year){
        try{
            if(customerId != null && customerId != '' && cardNumber != null && cardNumber != '' && CVC != null && CVC != '' && exp_Month != null && exp_Month != '' && exp_Year != null && exp_Year != ''){
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:My_Named_Credential/v1/payment_methods');
                req.setMethod('POST'); 
                req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
                
                String cardInfo = 'type=card&card[number]='+cardNumber+'&card[exp_month]='+Integer.valueOf(exp_Month)+'&card[exp_year]='+Integer.valueOf(exp_Year)+'&card[cvc]='+Integer.valueOf(CVC);
                req.setBody(cardInfo);
                Http http = new Http();
                HTTPResponse res = http.send(req);
                System.debug(res.getBody());
                JSONParser parser = JSON.createParser(res.getBody());
                parser.nextToken();
                parser.nextValue();
                String newPaymentMethodId = String.valueof(parser.getText());
                System.debug('newPaymentMethod : '+newPaymentMethodId);
                return attachCustomerPaymentMethod(newPaymentMethodId, customerId);
            }
            
        }catch(Exception Err){
            System.debug(LoggingLevel.ERROR, 'Exception Details: Line Number Is : '+Err.getLineNumber()+' | Cause Is : '+Err.getCause()+' | Meassage Is : '+Err.getMessage()+' | Trace Is : '+Err.getStackTraceString());
        }
        return null;
    }
    @AuraEnabled
    public static string attachCustomerPaymentMethod(String pm_Id, string cus_Id){
        try {
            if(pm_Id != null && pm_Id != '' && cus_Id != null && cus_Id != ''){
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:My_Named_Credential/v1/payment_methods/'+pm_Id+'/attach');
                req.setMethod('POST'); 
                req.setHeader('Content-Type', 'application/x-www-form-urlencoded');            
                String cardInfo = '&customer='+cus_Id;
                req.setBody(cardInfo);
                Http http = new Http();
                HTTPResponse res = http.send(req);
                System.debug(res.getBody());
                JSONParser parser = JSON.createParser(res.getBody());
                parser.nextToken();
                parser.nextValue();
                String newPaymentMethodId = String.valueof(parser.getText());
                System.debug('Attach newPaymentMethod : '+newPaymentMethodId);
                return newPaymentMethodId;
            }
            
        } catch (Exception Err) {
            System.debug(LoggingLevel.ERROR, 'Exception Details: Line Number Is : '+Err.getLineNumber()+' | Cause Is : '+Err.getCause()+' | Meassage Is : '+Err.getMessage()+' | Trace Is : '+Err.getStackTraceString());    
        }
        return null;
    } 
    @AuraEnabled
    public static string createProduct(String product_name){
        try {
            if(product_name != null && product_name != ''){
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:My_Named_Credential/v1/products');
                req.setMethod('POST'); 
                req.setHeader('Content-Type', 'application/x-www-form-urlencoded');            
                String prod_Info = '&name='+product_name;
                req.setBody(prod_Info);
                Http http = new Http();
                HTTPResponse res = http.send(req);
                System.debug(res.getBody());
                JSONParser parser = JSON.createParser(res.getBody());
                parser.nextToken();
                parser.nextValue();
                String new_Prod_Id = String.valueof(parser.getText());
                System.debug('new_Prod_Id : '+new_Prod_Id);
                return new_Prod_Id;
            }
            
        } catch (Exception Err) {
            System.debug(LoggingLevel.ERROR, 'Exception Details: Line Number Is : '+Err.getLineNumber()+' | Cause Is : '+Err.getCause()+' | Meassage Is : '+Err.getMessage()+' | Trace Is : '+Err.getStackTraceString());    
        }
        return null;
    }
    @AuraEnabled
    public static string createPrice(Decimal unitPrice, string pro_Id){
        try {
            if(unitPrice != null && pro_Id != null && pro_Id != ''){
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:My_Named_Credential/v1/prices');
                req.setMethod('POST'); 
                req.setHeader('Content-Type', 'application/x-www-form-urlencoded');            
                String price_Info = '&unit_amount='+unitPrice+'&currency=inr&product='+pro_Id;
                req.setBody(price_Info);
                Http http = new Http();
                HTTPResponse res = http.send(req);
                System.debug(res.getBody());
                JSONParser parser = JSON.createParser(res.getBody());
                parser.nextToken();
                parser.nextValue();
                String new_Price_Id = String.valueof(parser.getText());
                System.debug('new_Price_Id : '+new_Price_Id);
                return new_Price_Id;
            }
            
        } catch (Exception Err) {
            System.debug(LoggingLevel.ERROR, 'Exception Details: Line Number Is : '+Err.getLineNumber()+' | Cause Is : '+Err.getCause()+' | Meassage Is : '+Err.getMessage()+' | Trace Is : '+Err.getStackTraceString());    
        }
        return null;
    }
    @AuraEnabled
    public static string createCheckOutSession(Integer quantity, String price_Id, String cus_Id){
        try {
            if(price_Id != null && price_Id != '' && cus_Id != null && cus_Id != '' && quantity != null){
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:My_Named_Credential/v1/checkout/sessions');
                req.setMethod('POST'); 
                req.setHeader('Content-Type', 'application/x-www-form-urlencoded');            
                String price_Info = 'success_url=https://example.com/success&cancel_url=https://example.com/cancel&line_items[0][price]='+price_Id+'&line_items[0][quantity]='+quantity+'&mode=payment&customer='+cus_Id;
                req.setBody(price_Info);
                Http http = new Http();
                HTTPResponse res = http.send(req);
                System.debug(res.getBody());
                JSONParser parser = JSON.createParser(res.getBody());
                parser.nextToken();
                parser.nextValue();
                String new_Checkout_Id = String.valueof(parser.getText());
                System.debug('new_Checkout_Id : '+new_Checkout_Id);
                return new_Checkout_Id;
            }
           
        } catch (Exception Err) {
            System.debug(LoggingLevel.ERROR, 'Exception Details: Line Number Is : '+Err.getLineNumber()+' | Cause Is : '+Err.getCause()+' | Meassage Is : '+Err.getMessage()+' | Trace Is : '+Err.getStackTraceString());    
        }
        return null;
    }
    @AuraEnabled
    public static Boolean checkNullData(String cartId, String cardNumber, String CVV, String exp_Month, String exp_Year, String card, String nameOnCard, String consumerName, String consumerEmail, String totalAmount){
        try {
           List<String> cartDataList = new List<String>();
           cartDataList.add(cartId);
           cartDataList.add(cardNumber);
           cartDataList.add(CVV);
           cartDataList.add(exp_Month);
           cartDataList.add(exp_Year);
           cartDataList.add(card);
           cartDataList.add(nameOnCard);
           cartDataList.add(consumerName);
           cartDataList.add(consumerEmail);
           cartDataList.add(totalAmount);
           for(String chk: cartDataList){
               if(chk == null || chk == ''){
                   return false;
               }
           }
           return true;
        } catch (Exception Err) {
            System.debug(LoggingLevel.ERROR, 'Exception Details: Line Number Is : '+Err.getLineNumber()+' | Cause Is : '+Err.getCause()+' | Meassage Is : '+Err.getMessage()+' | Trace Is : '+Err.getStackTraceString());    
        }
        return null;
    }
    public class BillingAddressWrap {
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled
        public String value {get;set;}
 
    }
}
