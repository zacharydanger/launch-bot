
int armed_status = 0;
int button_light_pin = 2;
const int armed_pin = 4;
const int big_button_pin = 7;

//development status pins
const int dev_green = 3;
const int dev_yellow = 5;
const int dev_red = 6;

const int dev_pins[3] = {dev_green, dev_yellow, dev_red};

long dev_yellow_next_change = 0;
int dev_yellow_next_value = 0;
unsigned int yellow_modifier = 1;

long red_next_change = 0;
int red_next_val = 0;
unsigned int red_modifier = 1;

int dev_status_index = 0;

int big_button_status = LOW;
int big_button_last_status = LOW;

long time = 0;
const long debounce = 300;

long next_deploy = 0;

void setup() {
	pinMode(button_light_pin, OUTPUT);
	pinMode(armed_pin, INPUT);
	pinMode(big_button_pin, INPUT);

	pinMode(dev_green, OUTPUT);
	pinMode(dev_yellow, OUTPUT);
	pinMode(dev_red, OUTPUT);

	Serial.begin(9600);
}

void pulse_thing(int pin, long &next_time, unsigned int &modifier, int &next_val, int next_bump = 50, int step = 10) {
	if(millis() > next_time) {
		analogWrite(pin, next_val);

		next_time = millis() + next_bump;
		next_val += (step * modifier);

		if(next_val >= 255) {
			modifier = -1;
		} else if(next_val <= 0) {
			modifier = 1;
		}

		next_val = constrain(next_val, 0, 255);
	}
}

void loop() {
	check_armed();
	light_button();
	read_button();
	deploy_code();
	set_dev_status(1);

	pulse_thing(dev_pins[2], red_next_change, red_modifier, red_next_val, 25, 20);
	pulse_thing(dev_pins[1], dev_yellow_next_change, yellow_modifier, dev_yellow_next_value, 25);
	pulse_thing(dev_pins[0], dev_yellow_next_change, yellow_modifier, dev_yellow_next_value, 50, 5);
}

void set_dev_status(int status) {
	dev_status_index = status;
}

void pulse_dev_yellow() {
	pulse_thing(dev_pins[1], dev_yellow_next_change, yellow_modifier, dev_yellow_next_value);
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
	if(HIGH == big_button_status && LOW == big_button_last_status && millis() - time > debounce && HIGH == armed_status) {
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
