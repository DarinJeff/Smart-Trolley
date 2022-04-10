const int sensor_count = 8;
const int pingPins[sensor_count] = {12,11,10,9,8,7,6,5};
int min_dist = 120;
void setup() {
  Serial.begin(9600);
  pinMode(1, OUTPUT);
}

void loop() {
  long durations[sensor_count], cms[sensor_count];
  min_dist = 150;

  for (int i = 0; i < sensor_count; i++) {
    pinMode(pingPins[i], OUTPUT);
    digitalWrite(pingPins[i], LOW);
    delayMicroseconds(2);
    digitalWrite(pingPins[i], HIGH);
    delayMicroseconds(5);
    digitalWrite(pingPins[i], LOW);
    
    pinMode(pingPins[i], INPUT);
    durations[i] = pulseIn(pingPins[i], HIGH);
    
    cms[i] = microsecondsToCentimeters(durations[i]);
    min_dist = min(min_dist, cms[i]);
    
//    Serial.print("Sensor ");
//    Serial.print(i);
//    Serial.print(": ");
//    Serial.print(cms[i]);
//    Serial.print("   ");

    Serial.println(cms[i]);
    delay(250);
  }

//  Speaker Part
  Serial.println();
  
  tone(3,500 - min_dist*10, 100); 
  delay(50);
  noTone(3); 

  Serial.println(-1);

// LED part
  if(min_dist<10){
    digitalWrite(8, HIGH);   
    delay(10);              
    digitalWrite(8, LOW);   
  }
}

long microsecondsToCentimeters(long microseconds) {
  return microseconds / 29 / 2;
}
