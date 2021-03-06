// Pente by Sarah Prata
// RULES: 
// Players take turns placing their chips on the board
// The goal is to get 5 pieces in a row in any direction or capture 5 sets of your oppenent's pieces
// You can capture chips by placing your chips outside of a pair 
//      i.e. XOOX will capture the set of OO if you are team X
// Once captured these pieces are removed from the board
// If you place your chips in between a capture position, it will not count as a capture:
//      0X_0 -> 0XX0 will not result in a capture of X
// As soon as a player gets 5 pieces in a row or captures 5 sets, the game will be over
// 
// HOW TO PLAY:
// Open the file in Processing IDE (download here: https://processing.org/download/)
// Press the play button in the top right hand corner and a board will appear in front of you
// Click anywhere on the board to put down your first chip 
// (NOTE: According to standard Pente rules, the first move should always be in the center)
// After your chip appears on the board, player 2 may click anywhere to put down his/her chip
// When you capture chips, they will display below your team color
// The game will display "GAME OVER" when a player has won.

// Global Variables:
Boolean firstPlayer = true;
int boardSize = 12;
int[][] Board;
Boolean GameOver = false;
int boardHeight = 600;
int capturedSetsCountRed = 0;
int capturedSetsCountBlue = 0;


void setup()
{
  size(600,750);
  background(255);
  textAlign(CENTER);
  textSize(30);
  Board = new int[boardSize][];
  initBoard();
}


void initBoard()
{
  for(int i = 0; i < boardSize; i++)
  {
    Board[i] = new int[boardSize];
    for(int j = 0; j < boardSize; j++)
    {
      Board[i][j] = 0;
    }
  }
  drawBoard();
}


// draw() is a standard processing function
// It must be called when wanting the display to change over time
void draw()
{
    if(GameOver)
    {
      drawGameOver();
       
    }
}

// This is where most of the logic happens
// Occurs when a mouse click is detected
void mouseClicked() {
    if(validMove())
    {
      firstPlayer = !firstPlayer;
      int[] coords = move();
      ArrayList<Coords> listOfRecentCaptures = getCaptures(coords);
      adjustCaptureCountWithRecentCaptures(listOfRecentCaptures);
      removeCapturedChipsFromBoard(listOfRecentCaptures);
     
      if(fiveInARow() || capturedSetsCountRed >= 5 || capturedSetsCountBlue >= 5)
      {
        GameOver = true;
      }
      redrawBoard();
      drawScore();
    }
}



// Places chip on board based off of the mouse click's location. 
// Returns coordinates of the player's move
int[] move()
{
    int team = determineWhichTeamsTurn();
    if(team == 1) { fill(0,50,200); }
    else { fill(200, 50, 0); }
    float xInTermsOfBoard = mouseX/( width /boardSize*1.0); 
    float yInTermsOfBoard = mouseY/( boardHeight/boardSize*1.0);
    
    int xToDisplay = round(xInTermsOfBoard)*(boardHeight/boardSize);
    int yToDisplay = round(yInTermsOfBoard)*(boardHeight/boardSize);
    
    ellipse(xToDisplay, yToDisplay, 20,20);
    Board[round(xInTermsOfBoard)][round(yInTermsOfBoard)] = team;
    //printBoard();
    int[] coords = { round(xInTermsOfBoard), round(yInTermsOfBoard) };
    return coords;
}


// Given thelastMoveCoord checks for captures 
// Returns a list of pairs of coordinates of stones that have been captured. 
// If two or more sets have been captured the list is as follows:
// [ set1stone1.x, set1stone1.y, set1stone2.x, set1stone2.y, set2stone1.x, set2stone1.y, set2stone2.x, set2stone2.y, ... ]
ArrayList<Coords> getCaptures(int[] lastMoveCoord)
{
  ArrayList<Coords> listOfCoordinates;
  listOfCoordinates = new ArrayList<Coords>();
  int self = determineWhichTeamsTurn();
  int enemy = determineWhichTeamsWaiting();
  
  //check in every direction from that point
  //we want to check for the opposite of the colors 
  int x = lastMoveCoord[0];
  int y = lastMoveCoord[1];
  
  for(int i = y - 1; i <= y + 1; i++)
  {
   for(int j = x - 1; j <= x + 1; j++)
   {
     if(inBounds(i,j) && Board[j][i] == enemy)
     {
       //calc difference between x and i, y and j
       //Alg for second step is get difference then multiply by 2 :)
       int diffX = j - x;
       int diffY = i - y;
       int j2 = x + diffX*2;
       int i2 = y + diffY*2;
       if(inBounds(j2,i2) && Board[j2][i2] == enemy)
       {
         //Want to check if next is self, alg is get original difference then multiply by 2
         int j3 = x + diffX*3;
         int i3 = y + diffY*3;
         if(inBounds(j3,i3) && Board[j3][i3] == self)
         {
           //removeFromBoard(j, i, j2, i2, listOfCoordinates);
           listOfCoordinates.add(new Coords(j, i));
           listOfCoordinates.add(new Coords(x + diffX*2, y + diffY*2));
         }
       }
     }
   }
  }
  return listOfCoordinates;
}


// Removes a chips by setting its location value to 0
void removeFromBoard(int x1, int y1, int x2, int y2)
{
  Board[x1][y1] = 0;
  Board[x2][y2] = 0;
}


// Goes through the list of all recently captured coordinates
// Uses removeFromBoard() to actually remove the chips
void removeCapturedChipsFromBoard(ArrayList<Coords> coordList)
{
  for(int i = 0; i < coordList.size(); i += 2)
  {
    removeFromBoard(coordList.get(i).x, coordList.get(i).y, coordList.get(i+1).x, coordList.get(i+1).y);
  }
  
}


// Increase the count of captured sets relative to the team who did he capturing
void adjustCaptureCountWithRecentCaptures(ArrayList<Coords> listOfRecentCaptures)
{
  // Note: We divide by four because the list is structured [ Coord.x, Coord.y Coord2.x Coord2.y ] For each set of chips
  for( int i = 0; i < listOfRecentCaptures.size()/2; i++)
  {
    if(firstPlayer)
    {
      capturedSetsCountBlue += 1;
    }
    else
    {
      capturedSetsCountRed += 1;
    }
  }
}


// ******************************* FLOW OF LOGIC FUNCTIONS ******************************* //

// Goes through every location on the board, when reaches a non empty space,
// it checks to see if there are 5 in a row using checkFiveInARow(). 
// the directions are:
//  (1,0) for positive X (horizontal)
//  (0,1) for positive Y where positive is down (vertical) 
//  (1,1) for positive X and Y (diagonal from Left Top to Right Down)
//  (-1,1) for positive X and Y (diagonal from Right Top to Left Down)
// NOTE: Because we are going through the board from Left to Right and Down, 
// we do not need to check any other directions then the 4 listed
Boolean fiveInARow()
{
  int player = determineWhichTeamsTurn();
  for(int i = 0; i < boardSize; i++)
  {
    for(int j = 0; j < boardSize; j++)
    {
      if(Board[i][j] == player)
      {
        //checks Horizontally, Vertically, Diagonally Left and Diagonally Right in that order
        if(checkFiveInARow( i, j, player, 1, 0) || (checkFiveInARow( i, j, player, 0, 1)) 
        || (checkFiveInARow( i, j, player, 1, 1))  || (checkFiveInARow( i, j, player, -1, 1)))
        {
          return true;
        }
      }
    }
  }
  return false;
}

// Based on the direction given, checks to see if there are five chips of the same color in a row
// The pattern will be broken if it goes off the screen or the chip in the space does not match that of the player
Boolean checkFiveInARow(int i, int j, int player, int xDirection, int yDirection)
{
  int k = 0;
  Boolean broken = false;
  while(k < 5 && !broken)
  {
    if(!inBounds(i+k*xDirection, j-k*yDirection) || Board[i+k*xDirection][j-k*yDirection] != player)
    {
      broken = true;
    }
    k++;
  }
  if(broken == false && k >= 5)
  {
    return true;
  }
  return false;
}

// Checks to see if the move is valid based on staying in bounds and that the spot is not already taken
Boolean validMove()
{
  float xInTermsOfBoard = mouseX/( width /boardSize*1.0); 
  float yInTermsOfBoard = mouseY/( boardHeight/boardSize*1.0);
  int roundedX = round(xInTermsOfBoard);
  int roundedY = round(yInTermsOfBoard);
  if( !inBounds(roundedX, roundedY) || Board[roundedX][roundedY] != 0){
    return false;
  }
  return true;
}


// Checks to see if the array index is not outside of 0 or boardSize in any direction
Boolean inBounds(int i, int j)
{
  return (i >= 0 && j >= 0 && i < boardSize && j < boardSize);
}


int determineWhichTeamsTurn()
{
  if(firstPlayer) 
  { 
    fill(0,50,200); 
    return 1; 
  }
  fill(200, 50, 0); 
  return 2; 
}


int determineWhichTeamsWaiting()
{
  if(firstPlayer) 
  { 
    return 2; 
  }
  return 1; 
}



// ******************************* DRAW TO SCREEN FUNCTIONS ******************************* //

void redrawBoard()
{
  background(255);
  drawBoard();
  for(int i = 0; i < boardSize; i++)
  {
    for(int j = 0; j < boardSize; j++)
    {
      if(Board[j][i] != 0)
      {
        if(Board[j][i] == 1) { fill(0,50,200); }
        else { fill(200, 50, 0); }
        int xToDisplay = round(j)*(boardHeight/boardSize);
        int yToDisplay = round(i)*(boardHeight/boardSize);
        ellipse(xToDisplay, yToDisplay, 20,20);
      }
    }
  }
}


void drawRedCaptureVisual()
{
  int offset = 80;
  for(int i = 0; i < 5; i++)
  {
    if( i < capturedSetsCountRed ) { fill(0,50,200); }
    else { noFill(); }
    ellipse( i * 30 + offset, height - (height - boardHeight)/2 + 30, 10, 10);
    ellipse( i * 30 + offset + 12, height - (height - boardHeight)/2 + 30, 10, 10);
  }
}


void drawBlueCaptureVisual()
{
  int offset = width/2 + 80;
  for(int i = 0; i < 5; i++)
  {
    if( i < capturedSetsCountBlue ) { fill(200,50,0);  }
    else { noFill(); }
    ellipse( i * 30 + offset, height - (height - boardHeight)/2 + 30, 10, 10);
    ellipse( i * 30 + offset + 12, height - (height - boardHeight)/2 + 30, 10, 10);
  }
}


void drawScore()
{
  textSize(22);
  if(!firstPlayer)
  {
    fill(0,50,200);
    text("Blue's Turn", width/2, height - (height - boardHeight)/2 - 15);
  }
  else
  {
    fill(200,50,0);
    text("Red's Turn", width/2, height - (height - boardHeight)/2 - 15);
  }
  textSize(15);
  fill(200,50,0);
  text("Red's Capture Count", width/4, height - (height - boardHeight)/2);
  text(capturedSetsCountRed, width/4, height - (height - boardHeight)/2 - 30);
  fill(0,50,200);
  text("Blue's Capture Count", width/4*3, height - (height - boardHeight)/2);
  text(capturedSetsCountBlue, width/4*3, height - (height - boardHeight)/2 - 30);
  drawRedCaptureVisual();
  drawBlueCaptureVisual();
}


void drawBoard()
{
  strokeWeight(1);
  //noStroke();
  for(int i = 0; i <= width+2; i+=width/boardSize)
  {
    for(int j = 0; j <= boardHeight; j+=width/boardSize)
    {
      line(i, 0, i, boardHeight);
      line(0, j, width, j);
    }
  }
  fill(0);
  int ellipseSize = 5;
  ellipse(width/2, boardHeight/2,ellipseSize, ellipseSize);
  ellipse(width/12*2, boardHeight/2,ellipseSize, ellipseSize);
  ellipse(width - width/12*2, boardHeight/2,ellipseSize, ellipseSize);
  ellipse(width/2, boardHeight - boardHeight/12*2,ellipseSize, ellipseSize);
  ellipse(width/2, boardHeight/12*2,ellipseSize, ellipseSize);
  ellipse(width/12*2, boardHeight/12*2,ellipseSize, ellipseSize);
  ellipse(width - width/12*2, boardHeight - boardHeight/12*2,ellipseSize, ellipseSize);
  ellipse(width - width/12*2, boardHeight/12*2,ellipseSize, ellipseSize);
  ellipse(width/12*2, boardHeight - boardHeight/12*2,ellipseSize, ellipseSize);
}


void drawGameOver()
{
   fill(0, 100);
   rect(0, 0, width, height);
   textSize(100);
   fill(0,100,0);
   text("GAME OVER!", width/2, height/2);
   noLoop();
}


void printBoard()
{
  for(int i = 0; i < boardSize; i++)
  {
    for(int j = 0; j < boardSize; j++)
    {
      print(Board[j][i], " ");
    }
    print('\n');
  }
}