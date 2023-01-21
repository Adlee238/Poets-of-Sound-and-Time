//------------------------------------------------------------------------------
// name: favorites-in-a-mixer.ck
// desc: An interactive poem that asks the user a few questions, and generates a
//       poem based on that information using a Word2Vec Model.
// sorting: part of chAI (ChucK for AI)
//
// "[color], [animal], [food], [season]"
// -- a personal poem
//
// author: Andrew T. Lee
// date: January 2023
//------------------------------------------------------------------------------


// INITIALIZATIONS:

// Console Input
ConsoleInput in;
StringTokenizer tokenizer;

// Word2Vec Model
Word2Vec model;
me.dir() + "cmudict.txt" => string filepath;
//me.dir() + "cmudict.txt" => string filepath;
if( !model.load( filepath ) )
{
    <<< "cannot load model:", filepath >>>;
    me.exit();
}

// CONSTANTS
model.dim() => int VECTSIZE;
4 => int NWORDS;
4 => int NLINES;
4 => int NSTANZAS;
240::ms => dur T;
false => int shouldScaleTimeToWordLength;

// SOUND
Shakers shaker => NRev reverb => dac;
ModalBar marimba => dac;
// reverb wet/dry mix
.1 => reverb.mix;
// presets
6 => shaker.preset;
0.7 => shaker.energy;
0.1 => shaker.decay;
0 => marimba.preset;




// FUNCTIONS:

// make_theme: Takes in original user input and generates a theme line
fun string [] make_theme(string color, string animal, 
                               string food, string season) {
    string theme[NWORDS];
    
    color => theme[0];
    animal => theme[1];
    food => theme[2];
    season => theme[3];
    
    return theme;
}


// make_play_stanza: Takes in a line to generate and sonify
// a stanza by making various variations. Also takes in a 
// set of notes and uses them for the marimba. 
fun void make_play_stanza(string theme[], int notes[]) {
    string line[NWORDS];
    string mainWord;
    float mainWordVec[VECTSIZE];
    for ( int j; j < NWORDS; j++ ) {
        theme[j] => line[j];
    }
    line[0] => mainWord;
    model.getVector(mainWord, mainWordVec);
    
    for (int i; i < NLINES; i++) {
        for (int j; j < NWORDS; j++) {
            // play the current word
            chout <= line[j] <= " "; chout.flush();
            0.8 => shaker.noteOn;
            notes[j] => Std.mtof => marimba.freq;
            0.8 => marimba.noteOn;
            wait( T );
            if (j != NWORDS - 1) {
                0.8 => shaker.noteOn;
                wait( T );
            }
        
            // update word to be a blend between the current 
            // word with the main word of the stanza, phonetically
            if (j != 0) {
                float curWordVec[VECTSIZE];
                model.getVector(line[j], curWordVec);
                for( int v; v < VECTSIZE; v++ ) {
                    // find the average vector between the two words
                    (mainWordVec[v] + curWordVec[v]) / 2.0 => curWordVec[v];
                }
                string newWord[3];
                model.getSimilar(curWordVec, newWord.size(), newWord);
                newWord[ Math.random2(0, newWord.size()-1) ] => line[j];
            }
        }
        endl( 2*T );
        // update note set
        notes[i + 4] => notes[0];
    }
}


// change_theme: changes the order of a theme line by shifting 
// the element at the front to the end.
fun string[] change_theme( string line[] ) {
    string newLine[NWORDS];
    for ( int j; j < NWORDS - 1; j++ ) {
        line[j + 1] => newLine[j];
    }
    line[0] => newLine[NWORDS - 1];
    return newLine;
};


// Helper function: wait
fun void wait( dur T ) {
    T => now;
}

// Helper function: endl
fun void endl( dur T ) {
    chout <= IO.newline(); chout.flush();
    T => now;
}






// MAIN:

// Ask for user information
chout <= "Please type single-word answers below in lowercase only.";
chout <= IO.newline(); chout.flush();
in.prompt( "Your favorite color?" ) => now;
in.getLine() => string color;
in.prompt( "Your favorite animal? " ) => now;
in.getLine() => string animal;
in.prompt( "Your favorite food?" ) => now;
in.getLine() => string food;
in.prompt( "Your favorite season?" ) => now;
in.getLine() => string season;

// Get theme line: the stanza will revolve around this line
string theme[NWORDS];
make_theme( color, animal, food, season ) @=> theme;
// Note Sets
[65, 57, 55, 53, 64, 62, 60, 0] @=> int notes0[];
[69, 60, 58, 57, 67, 64, 65, 0] @=> int notes1[];
[72, 64, 62, 60, 70, 69, 67, 0] @=> int notes2[];
[65, 60, 57, 53, 67, 64, 65, 0] @=> int notes3[];
[notes0, notes1, notes2, notes3] @=> int noteSets[][];


// Print Title
chout <= IO.newline(); chout.flush();
chout <= color <= ", " <= animal <= ", " <= food <= ", and " <= season <= IO.newline(); chout.flush();
chout <= IO.newline(); chout.flush();
wait ( 2*T );

// Create and play 4 stanzas using different arrangements of 
// the theme line, such that each word has a chance to be the 
// "theme" of the stanza.
for (int s; s < NSTANZAS; s++) {
    noteSets[s] @=> int curNotes[];
    
    // play a stanza
    make_play_stanza( theme , curNotes);
    endl( 2*T );
    wait( 2*T );
    
    // change the theme line
    change_theme( theme ) @=> theme;
}

