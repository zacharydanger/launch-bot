
int armed_status = 0;
int button_light_pin = 2;
int armed_pin = 4;
int big_button_pin = 7;

int big_button_status = LOW;
int big_button_last_status = LOW;

long time = 0;
long debounce = 300;

long next_deploy = 0;

void setup() {
	pinMode(button_light_pin, OUTPUT);
	pinMode(armed_pin, INPUT);
	pinMode(big_button_pin, INPUT);

	Serial.begin(9600);
}

void loop() {
	check_armed();
	light_button();
	read_button();
	deploy_code();
}

/**
 * Checks whether or not the toggle switch has been armed.
 */
void check_armed() {
	armed_status = digitalRead(armed_pin);
}

/**
 * Triggers the relay to turn on the big red button's
 * 12V light.
 */
void light_button() {
	digitalWrite(button_light_pin, armed_status);
}

/**
 * Reads the big red button (and hopfully takes care to debounce)
 */
void read_button() {
	big_button_status = digitalRead(big_button_pin);
	if(HIGH == big_button_status && LOW == big_button_last_status && millis() - time > debounce) {
		time = millis();
		next_deploy = millis() + 500;
	}
	big_button_last_status = big_button_status;
}

/**
 * Calls out to C.I. Joe to run the tests and deploy the code.
 * 
 * @TODO: Actually implement this.
 */
void deploy_code() {
	if(millis() >= next_deploy && next_deploy > 0) {
		Serial.println("TODO: Deploying!");
		next_deploy = 0;
	}
}
