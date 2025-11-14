public class ContactStripeCustomerListIntegration {

public static final String STRIPE_API_URL = 'https://api.stripe.com/v1/customers';
public static final String STRIPE_SEARCH_API_URL = 'https://api.stripe.com/v1/customers/search';
public static final String STRIPE_API_KEY = 'sk_test_your_api_key_here'; // Replace with your actual Stripe API key
public static final String CONTENT_TYPE_HEADER = 'Content-Type';
public static final String CONTENT_TYPE = 'application/x-www-form-urlencoded';
public static final String AUTH_HEADER = 'Authorization';
public static final String AUTHORIZATION_HEADER = 'Bearer ' + STRIPE_API_KEY;
public static final String EMAIL_PARAM = 'email=';
public static final String NAME_PARAM = '&name=';
public static final String PHONE_PARAM = '&phone=';
public static final String ADDRESS_CITY_PARAM = '&address[city]=';
public static final String ADDRESS_COUNTRY_PARAM = '&address[country]=';
public static final String UTF8 = 'UTF-8';
public static final String POST_METHOD = 'POST';
public static final String GET_METHOD = 'GET';
public static final String SEARCH_QUERY_PARAM = '?query=';
public static final String SEARCH_EMAIL_PREFIX = 'email:\'';
public static final String SEARCH_EMAIL_SUFFIX = '\'';
public static final String DATA_PARAM = 'data';

public void processContactStripeCustomer(List<Contact> contacts) {
    List<Object> existingCustomers = new List<Object>();
    if(contacts == null || contacts.isEmpty()) {
        throw new StripeCustomerException('Contact list is null or empty');
    }
    for(Contact contact : contacts) {
        if(contact.Email == null) {
            throw new StripeCustomerException('Contact email is null for Contact Id: ' + contact.Id);
        }
        if (contact.LastName == null && contact.FirstName == null) {
            throw new StripeCustomerException('Contact name is null for Contact Id: ' + contact.Id);
        }
    }
    existingCustomers = searchCustomersByEmails(contacts);
    System.debug('Existing Customers: ' + existingCustomers);

    List<String> existingEmails = new List<String>();
    List<String> stripeCustomerIDs = new List<String>();
    for(Object custObj : existingCustomers) {
        Map<String, Object> custMap = (Map<String, Object>) custObj;
        if(custMap.containsKey('email')) {
            existingEmails.add((String) custMap.get('email'));
        }
        if(custMap.containsKey('id')) {
            stripeCustomerIDs.add((String) custMap.get('id'));
        }
    }

    for (Contact contact : contacts) {
    if(existingEmails.contains(contact.Email)) {
        String urlEncodedBody = buildURLEncodedBody(contact);
        String stripeCustomerID = stripeCustomerIDs[existingEmails.indexOf(contact.Email)];
        Map<String,Object> responseMap = postStripeCustomerUpdate(stripeCustomerID, urlEncodedBody);
    } else {
        String urlEncodedBody = buildURLEncodedBody(contact);
        Map<String,Object> responseMap = postStripeCustomerCreate(urlEncodedBody);
    }
    }
}

public Map<String,Object> postStripeCustomerUpdate(String stripeCustomerID, String urlEncodedBody) {
    HttpRequest request = new HttpRequest();
    request.setEndpoint(STRIPE_API_URL + '/' + stripeCustomerID);
    request.setMethod(POST_METHOD);
    request.setHeader(CONTENT_TYPE_HEADER, CONTENT_TYPE);
    request.setHeader(AUTH_HEADER, AUTHORIZATION_HEADER);
    request.setBody(urlEncodedBody);

    Http http = new Http();
    HttpResponse response = http.send(request);
    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
    return responseMap;
}

public Map<String,Object> postStripeCustomerCreate(String urlEncodedBody) {
    HttpRequest request = new HttpRequest();
    request.setEndpoint(STRIPE_API_URL);
    request.setMethod(POST_METHOD);
    request.setHeader(CONTENT_TYPE_HEADER, CONTENT_TYPE);
    request.setHeader(AUTH_HEADER, AUTHORIZATION_HEADER);
    request.setBody(urlEncodedBody);

    Http http = new Http();
    HttpResponse response = http.send(request);
    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
    return responseMap;
}

public String buildURLEncodedBody(Contact contact) {
    String emailEncodedBody = '';
    String nameEncodedBody = '';
    String phoneEncodedBody = '';
    String addressCityEncodedBody = '';
    String addressCountryEncodedBody = '';
    if (contact.Email != null) {
        emailEncodedBody =  EMAIL_PARAM + EncodingUtil.urlEncode(contact.Email, UTF8);
    }
    if (contact.FirstName != null && contact.LastName != null) {
        nameEncodedBody = NAME_PARAM + EncodingUtil.urlEncode(contact.FirstName + ' ' + contact.LastName, UTF8);
    }
    if (contact.Phone != null) {
        phoneEncodedBody = PHONE_PARAM + EncodingUtil.urlEncode(contact.Phone, UTF8);
    }
    if(contact.MailingCity != null){
        addressCityEncodedBody = ADDRESS_CITY_PARAM + EncodingUtil.urlEncode(contact.MailingCity, UTF8);
    }
    if(contact.MailingCountry != null){
        addressCountryEncodedBody = ADDRESS_COUNTRY_PARAM + EncodingUtil.urlEncode(contact.MailingCountry, UTF8);
    }
    String urlEncodedBody = emailEncodedBody + nameEncodedBody + phoneEncodedBody + addressCityEncodedBody + addressCountryEncodedBody;
    return urlEncodedBody;
}

public List<Object> searchCustomersByEmails(List<Contact> contacts) {
    List<Object> existingCustomers = new List<Object>();
    List<String> emails = new List<String>();
    for(Contact contact : contacts) {
        if(contact.Email != null) {
            emails.add(contact.Email);
        }
    }

    for (String email : emails) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(STRIPE_SEARCH_API_URL);
        req.setMethod(GET_METHOD);
        req.setHeader(AUTH_HEADER, AUTHORIZATION_HEADER);
        
        // Build query parameter
        String query = SEARCH_EMAIL_PREFIX + email + SEARCH_EMAIL_SUFFIX;
        req.setEndpoint(req.getEndpoint() + SEARCH_QUERY_PARAM + EncodingUtil.urlEncode(query, UTF8));
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> data = (List<Object>) result.get(DATA_PARAM);
            existingCustomers.addAll(data);
        }
    }
    return existingCustomers;
}

public class StripeCustomerException extends Exception {}
}