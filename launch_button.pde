#include <SPI.h>
#include <Ethernet.h>

int armed_status = 0;
int button_light_pin = 2;
const int armed_pin = 4;
const int big_button_pin = 7;

//development status pins
const int dev_green = 3;
const int dev_yellow = 5;
const int dev_red = 6;

const int live_green = 9;
const int live_yellow = 10;
const int live_red = 11;

const int led_pins[6] = {dev_green, dev_yellow, dev_red, live_green, live_yellow, live_red};

int pulse_pins[6] = {0, 0, 0, 0, 0, 0};

//how many milliseconds between steps?
const int yellow_speed = 30;
//lowest value for yellow LEDs
const int yellow_low = 16;

//amount to change in single step
const int red_speed = 325;
const int red_step = 255;

//threading via arrays?
long changes[6] = {0, 0, 0, 0, 0, 0};
unsigned int modifier[6] = {1, 1, 1, 1, 1, 1};
int pulse_vals[6] = {0, 0, 0, 0, 0, 0};

int pulse_deltas[6] = {25, yellow_speed, red_speed, 40, yellow_speed, red_speed};
int pulse_steps[6] = {10, 10, red_step, 10, 10, red_step};

int pulse_low[6] = {0, yellow_low, 0, 0, yellow_low, 0};
int pulse_high[6] = {255, 255, 255, 255, 255, 255};

int dev_status_index = 0;

int big_button_status = LOW;
int big_button_last_status = LOW;

long time = 0;
const long debounce = 300;

long next_deploy = 0;

byte mac[] = {  0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte ip[] = { 192,168,1,177 };
byte gateway[] = { 192,168,1,1};
byte server[] = { 192,168,1,112 }; // Google

Client client(server, 80);

long next_dev_check = 0;
long next_dev_reconnect = 0;

String dev_status = "none";

void setup() {
	pinMode(button_light_pin, OUTPUT);
	pinMode(armed_pin, INPUT);
	pinMode(big_button_pin, INPUT);

	pinMode(dev_green, OUTPUT);
	pinMode(dev_yellow, OUTPUT);
	pinMode(dev_red, OUTPUT);

	pinMode(live_green, OUTPUT);
	pinMode(live_yellow, OUTPUT);
	pinMode(live_red, OUTPUT);

	Ethernet.begin(mac, ip, gateway);
	delay(1000);

	Serial.begin(9600);
}

void loop() {
	light_button();
	read_button();
	deploy_code();

	if(millis() > next_dev_check) {
		check_dev_status();
		next_dev_check = millis() + 5000;
	}

	pulse_pins[0] = 0;
	pulse_pins[1] = 0;
	pulse_pins[2] = 0;
	if(dev_status == "good") {
		pulse_pins[0] = 1;
	} else if(dev_status == "build") {
		pulse_pins[1] = 1;
	} else if(dev_status == "bad") {
		pulse_pins[2] = 1;
	}

	pulse_all_pins();
}

void check_dev_status() {
	Serial.print("Trying to connect...");

	if(client.connect()) {
		Serial.print(" connected!\n");
		client.println("GET /ard.php HTTP1.0");
		client.println();

		delay(1000);

		String line = "";
		while(client.available()) {
			char c = client.read();
			line.concat(c);

			if(c == '\n') {
				line = "";
			}

			if(!client.available()) {
				dev_status = line;
				Serial.println(dev_status);
			}
		}

	} else {
		Serial.print(" failed.\n");
	}

	client.stop();
}

/**
 * Loops through all pins and pulses them if need be.
 */
void pulse_all_pins() {
	for(int i = 0; i <= 2; i++) {
		if(pulse_pins[i] > 0) {
			pulse_by_index(i);
		} else {
			analogWrite(led_pins[i], 0);
		}
	}
}

/**
 * Pulses an LED with a shit-ton of criteria.
 */
void pulse_led(int pin, long &next_time, unsigned int &modifier, int &next_val, int next_bump = 50, int step = 10, int low_val = 0, int high_val = 255) {
	if(millis() > next_time) {
		analogWrite(pin, next_val);

		next_time = millis() + next_bump;
		next_val += (step * modifier);

		if(next_val >= high_val) {
			modifier = -1;
		} else if(next_val <= low_val) {
			modifier = 1;
		}

		next_val = constrain(next_val, low_val, high_val);
	}
}

/**
 * Pulses the pin for a given index.
 */
void pulse_by_index(int index) {
	pulse_led(led_pins[index], changes[index], modifier[index], pulse_vals[index], pulse_deltas[index], pulse_steps[index], pulse_low[index], pulse_high[index]);
}

/**
 * Triggers the relay to turn on the big red button's
 * 12V light.
 */
void light_button() {
	digitalWrite(button_light_pin, digitalRead(armed_pin));
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
		pulse_pins[4] = 1;
		next_deploy = 0;
	}
}
