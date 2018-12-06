class Mover {
  PVector location;
  PVector velocity;
  PVector gravityForce;
  PVector friction;
  PVector acceleration;

  float normalForce = 1;
  float mu = 0.1;
  float frictionMagnitude = normalForce * mu;
  float gravityConstant = 1.5;

  boolean touchedBottom = false;
  boolean touchedLeft = false;
  boolean touchedRight = false;
  boolean touchedTop = false;

  Mover() {
    location = new PVector(0, -(rayonSphere + taillePlateauY/2), 0);
    velocity = new PVector(0, 0, 0);
    friction = new PVector(0, 0, 0);
    acceleration = new PVector(0, 0, 0);
    gravityForce = new PVector(0, 0, 0);
  }

  void update() {    
    gravityForce.x = gravityConstant * sin(rz);
    gravityForce.z = -gravityConstant * sin(rx);
    gravityForce.y = 0;

    PVector friction = velocity.copy();
    friction.mult(-1);
    friction.normalize();
    friction.mult(frictionMagnitude);

    acceleration = gravityForce;

    velocity.add(acceleration);
    velocity.add(friction);
    velocity.limit(topSpeed);

    location.add(velocity);
  }

  void checkEdges() {
    boolean bottom = false;
    boolean top = false;
    boolean right = false;
    boolean left = false;
    
    if (location.x >= taillePlateau/2 - rayonSphere/2 || location.x <= -taillePlateau/2 + rayonSphere/2) {
      if (location.x >= taillePlateau/2 - rayonSphere/2) {
        location.x = taillePlateau/2 - rayonSphere/2;
        right = true;
      } else {
        location.x = -taillePlateau/2 + rayonSphere/2;
        left = true;
      }
      velocity.x = velocity.x * -1;
    }

    if (location.z >= taillePlateau/2 - rayonSphere/2 || location.z <= -taillePlateau/2 + rayonSphere/2) {
      if (location.z >= taillePlateau/2 - rayonSphere/2) {
        location.z = taillePlateau/2 - rayonSphere/2;
        bottom = true;
      } else {
        location.z = -taillePlateau/2 + rayonSphere/2;
        top = true;
      }
      velocity.z = velocity.z * -1;
    }
    
    if((bottom && !touchedBottom) || (top && !touchedTop) || (right && !touchedRight) || (left && !touchedLeft)){
      float velocityMag = velocity.copy().mag();

      if (velocityMag > tresholdScore) {
        lastScore = -velocityMag;
        if (score + lastScore <= 0) {
          score = 0;
        } else {
          score += lastScore;
        }
      }
    }
    
    touchedBottom = bottom;
    touchedTop = top;
    touchedLeft = left;
    touchedRight = right;
  }

  void checkCylinderCollisions() {
    //we don't remove cylinders when we hit them
    for (PVector center2 : cylPos) {
      PVector center = new PVector(center2.x, location.y, center2.z);
      
      if (center.dist(location) <= cylinderBaseSize + rayonSphere) {
        float velocityMag = velocity.copy().mag();

        if (velocityMag > tresholdScore) {
          lastScore = velocityMag;
          score += lastScore;
        }

        //Location of ball on plane
        PVector location2D = new PVector(location.x, location.z);

        //Center of cylinder on plane
        PVector center2D = new PVector(center.x, center.z);

        //Position of ball with respect to the center (so that the ball can't go inside the cylinder)
        PVector posOfBall2D = location2D.copy().sub(center2D.copy()).normalize().mult(cylinderBaseSize + rayonSphere);
        location2D = center2D.copy().add(posOfBall2D.copy());

        //Update location
        location = new PVector(location2D.x, location.y, location2D.y);

        PVector n = posOfBall2D.copy().normalize();

        //Velocity of ball in 2D
        PVector velocity2D = new PVector(velocity.x, velocity.z);

        //New velocity of ball in 2D
        PVector newVelocity2D = velocity2D.copy().sub(n.copy().mult(2 * velocity2D.copy().dot(n.copy())));

        velocity = new PVector(newVelocity2D.x, velocity.y, newVelocity2D.y);
      }
    }
  }
}