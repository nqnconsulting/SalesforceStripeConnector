public class ContactStripeCustomerIntegration {

public static final String STRIPE_API_URL = 'https://api.stripe.com/v1/customers';
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

public HttpResponse postStripeCustomer(Contact contact) {
    String urlEncodedBody =
    EMAIL_PARAM + EncodingUtil.urlEncode(contact.Email, UTF8) +
    NAME_PARAM + EncodingUtil.urlEncode(contact.FirstName + ' ' + contact.LastName, UTF8) +
    PHONE_PARAM + EncodingUtil.urlEncode(contact.Phone, UTF8) +
    ADDRESS_CITY_PARAM + EncodingUtil.urlEncode(contact.MailingCity, UTF8) +
    ADDRESS_COUNTRY_PARAM + EncodingUtil.urlEncode(contact.MailingCountry, UTF8);


    HttpRequest request = new HttpRequest();
    request.setEndpoint(STRIPE_API_URL);
    request.setMethod(POST_METHOD);
    request.setHeader(CONTENT_TYPE_HEADER, CONTENT_TYPE);
    request.setHeader(AUTH_HEADER, AUTHORIZATION_HEADER);
    request.setBody(urlEncodedBody);

    Http http = new Http();
    HttpResponse response = http.send(request);
    return response;
}
}