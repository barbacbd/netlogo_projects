;; Authors: Brent Barbachem and Mariaclara Ludovici
;; Date: March 21, 2016
;;
;; This program and/or simulation was created in accordance with
;; the Old Dominion University Honor Policy and the BNAL 722 -
;; Agent Based Modeling and Simulation course. The code produced
;; also corresponds to a preexisting paper authored by
;; Mariaclara Ludovici.

;; --- FROM THE INTERFACE  ---
;; initial_eu_number, initial_immigrants_number, eu_color, im_color,
;; search_area, prisoners-perc, chicken-perc, coordinate-perc,
;; deadlock-perc, harmony-perc, and preference

;; the values associated with european and immigrant policies
globals[ eu_val im_val ]

;; turtles will own a current policy (whether they are supporting european or immigrant)
;; and their weights for a strategy (the current strategy that the turtle will use for game theory)
turtles-own[ policy hp cop dp chp pp ]



to setup
  clear-all ;; erase all information

  ;; error checking - ensure the probabilities add to 100%
  if (harmony-perc + coordinate-perc + deadlock-perc + chicken-perc + prisoners-perc) != 100 [
    show "Percentages do not add to 100%"
    set harmony-perc 20
    set deadlock-perc 20
    set prisoners-perc 20
    set coordinate-perc 20
    set chicken-perc 20
  ]

  ;; set the global variable values
  set eu_val 1
  set im_val -1

  create-turtles initial_eu_number[
    setxy random-xcor random-ycor
    set policy eu_val ;; they start by favoring european policy
    set-color         ;; recolor the turtles
  ]

  create-turtles initial_immigrants_number[
    setxy random-xcor random-ycor
    set policy im_val ;; they start by favoring immigrant policy
    set-color         ;; recolor the turtles
  ]

  ;; set the percentages for each agent - these will all be the same
  ;; at this point in the simulation, but each agent will be relatively
  ;; unique by the end of the simulation
  ask turtles[
    set hp harmony-perc / 100.0
    set cop coordinate-perc / 100.0
    set dp deadlock-perc / 100.0
    set pp prisoners-perc / 100.0
    set chp chicken-perc / 100.0
    set shape "person"
  ]

  reset-ticks ;; reset the global counter
end


to go
  ;; set up simple agent sets to pass to the dual procedure
  ;; IMPORTANT - this will ensure that the agent plays a game
  ;; against a turtle that was different from them at the beginning
  ;; of the go procedure
  let eu_group turtles with [ policy = eu_val ]
  let im_group turtles with [ policy = im_val ]

  ask turtles [
    wiggle    ;; set the turtle facing in a random direction
    move      ;; wrapper to forward 1

    ;; use game theory to test which culture will overcome the other
    ifelse policy = eu_val [ dual im_group ][ dual eu_group ]

    set-color ;; recolor the turtles to show updated policy preferences
  ]

  clear-links ;; drop all links from this tick
  tick        ;; increment the ticks
end



;; twist right and left a random amount to simulate a wiggle movement
to wiggle
    right random 90
    left random 90
end

;; forward wrapper function that provides the ability for a user to pass
;; in different parameters in case of new extensions.
to move
  forward 1
end

;; user defined procedure to recolor the turtles based on whether
;; they are favoring immigrant policy or european policy
to set-color
  ifelse policy = eu_val [ set color eu_color][ set color im_color ]
end


;; try to find a neighbor within a certain radius of you that is not the same
;; color as you. The turtles are paired together and the predetermined outcomes
;; are used to simulate the effects of running several different types of
;; game theory scenarios on the turtles.
;; It is important to note the assumption of RATIONALITY here in order to simplify
;; the game theory tactics
to dual [ candidates ]
  let target one-of candidates in-radius search_area

  ;; make sure that there is a target - if there isn't one
  ;; then skip this section for this time tick
  if target != nobody [
    ;; pick a random game based on the wieghts or probabilities from the interface
    let game random-game

    if game = 1 [
      ;; Harmony Game -- The Nash Equillibrium suggests that the
      ;; immigrants will interate into the host society (EU) because,
      ;; it is the maximum payoff

      ask target [ set policy eu_val ]
      set policy eu_val
    ]

    if game = 2 [
      ;; Deadlock Game -- The Nash Equillibrium suggests that the
      ;; hosts will defect into the immigrant cultures because,
      ;; it is the maximum payoff

      ask target [ set policy im_val ]
      set policy im_val
    ]

    if game = 3 [
      ;; Prisoner's Dilemma -- In the case of immigrants and Europeans,
      ;; there is no nash equilibrium. In fact, either party will have the
      ;; highest payout when one defects and the other cooperates or stays
      ;; skew the decision based on the population percentage -- goes along with the
      ;; segregation theory or model
      ifelse random-float 1.0 <=
      (count turtles with[ color = eu_color] / (initial_eu_number + initial_immigrants_number)) [
        ;; Find the immmigrat player and change their
        ;; cultural policy to show that they defected
        ifelse [policy] of target = im_val [
          ask target [ set policy eu_val ]
        ][ set policy eu_val ]
      ]
      [
        ;; Find the European player and change their
        ;; cultural policy to show that they defected
        ifelse [policy] of target = eu_val [
          ask target [ set policy im_val ]
        ][ set policy im_val ]
      ]
    ]

    if game = 4 [
      ;; Coordination Game -- In this case neither culture is doing any better,
      ;; so either the parties will agree to use the adopt the european culture
      ;; or to use the immigrant culture
      ;; skew the decision based on the population percentage -- goes along with the
      ;; segregation theory or model

      ;; 50-50 chance on which is used
      ifelse random-float 1.0 <=
      (count turtles with[ color = eu_color] / (initial_eu_number + initial_immigrants_number)) [
        ;; use the european culture
        ask target [set policy eu_val]
        set policy eu_val
      ]
      [
        ;; use the immigrant culture
        ask target [set policy im_val]
        set policy im_val
      ]
    ]

    if game = 5 [
      ;; Chicken Game -- The players will always avoid picking the exact same choice;
      ;; if player one picks EU-ID then player two picks I-ID, and when player one
      ;; picks I-ID, then player two picks EU-ID

      ifelse random-float 1.0 <= 0.5 [
        ;; player 1 -> EU-ID, player 2 -> I-ID
        set policy eu_val
        ask target [set policy im_val]
      ]
      [
        ;; player 1 -> I-ID, player 2 -> EU-ID
        set policy im_val
        ask target [set policy eu_val]
      ]
    ]

    ;; add any extension code for more game types
  ]

end

;; randomly choose a game based on the turtles probability of choosing a game that
;; they are used to playing. Update the turtles probabilities of choosing a game
;; after this rounds game has been selected.
to-report random-game
  let game-perc random-float 1.0
  let game 0
  let place hp

  if hp > 0.0 [
    if game-perc <= place [ set game 1 ]
  ]

  if dp > 0.0 [
    if game-perc > place and game-perc <= place + dp [ set game 2 ]
    set place place + dp
  ]

  if pp > 0.0 [
    if game-perc > place and game-perc <= place + pp [ set game 3 ]
    set place place + pp
  ]

  if cop > 0.0 [
    if game-perc > place and game-perc <= place + cop [ set game 4 ]
    set place place + cop
  ]

  if chp > 0.0 [
    if game-perc > place and game-perc <= place + chp [ set game 5 ]
  ]

  adjust game ;; adjust this turtles preferences for games

  report game
end

;; Adjust the turtles preference or probability of picking
;; each game based on their current selection
;; This procedure incorporates a dimension of learning with each agent
to adjust [ game ]
  let minus preference / 4.0

  set hp max list (hp - minus) 0.00
  set dp max list (dp - minus) 0.00
  set pp max list (pp - minus) 0.00
  set cop max list (cop - minus) 0.00
  set chp max list (chp - minus) 0.00  
  
  ;; Add the preference and the minus value in order to make up for
  ;; subtracting the value earlier. This may lead to minor offset errors 
  ;; when the value accidentally goes below 0.0, but it will be made up
  ;; over time.
  ifelse game = 1[set hp min list (hp + (preference + minus)) 1.00 ]
  [
    ifelse game = 2[set dp min list (dp + (preference + minus)) 1.00 ]
    [
      ifelse game = 3[set pp min list (pp + (preference + minus)) 1.00 ]
      [
        ifelse game = 4[set cop min list (cop + (preference + minus)) 1.00 ]
        [
          if game = 5[set chp min list (chp + (preference + minus)) 1.00 ]
        ]]]]
end
@#$#@#$#@
GRAPHICS-WINDOW
360
13
799
473
16
16
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
109
51
172
84
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
25
51
88
84
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
11
93
186
126
initial_eu_number
initial_eu_number
1
1000
282
1
1
NIL
HORIZONTAL

SLIDER
10
133
185
166
initial_immigrants_number
initial_immigrants_number
1
1000
294
1
1
NIL
HORIZONTAL

INPUTBOX
250
81
324
141
eu_color
96
1
0
Color

INPUTBOX
251
149
325
209
im_color
26
1
0
Color

SLIDER
10
174
186
207
search_area
search_area
1
5
5
1
1
NIL
HORIZONTAL

PLOT
11
425
237
600
Host vs Immigrants
Time
Number of Members
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -13791810 true "" "plot count turtles with [policy = eu_val]"
"pen-1" 1.0 0 -2674135 true "" "plot count turtles with [policy = im_val]"

MONITOR
259
466
333
511
Hosts
count turtles with [policy = eu_val]
17
1
11

MONITOR
260
524
334
569
Immigrants
count turtles with [policy = im_val]
17
1
11

SLIDER
11
217
184
250
harmony-perc
harmony-perc
0
100
20
1
1
percent
HORIZONTAL

SLIDER
11
260
184
293
deadlock-perc
deadlock-perc
0
100
20
1
1
percent
HORIZONTAL

SLIDER
11
302
184
335
prisoners-perc
prisoners-perc
0
100
20
1
1
percent
HORIZONTAL

SLIDER
11
381
183
414
chicken-perc
chicken-perc
0
100
20
1
1
percent
HORIZONTAL

SLIDER
12
342
184
375
coordinate-perc
coordinate-perc
0
100
20
1
1
percent
HORIZONTAL

SLIDER
264
231
297
381
preference
preference
0
1.0
0.12
.02
1
NIL
VERTICAL

@#$#@#$#@
## WHAT IS IT?

Current, world, news has displayed the mass amount of immigrants attempting to enter into Europe from the southern nations around Africa and the Middle East. Many immigrants have been pardoned and allowed to enter the European nations, but there has been little or no discussion about the lasting effects that meshing cultures could bring. It would not be fair to the Europeans or the immigrants to declare that only one culture may survive, but is there a way to peacefully coexist? Will one culture inadvertently take over the other culture? The purpose of this project is to use Agent Based Modeling and Simulation to study the possible effects of immigration into Europe from outside nations. 

## HOW IT WORKS

The agents are controlled by a procedure called dual. Dual will pick a random game theory game and [predetermined] equillibrium state(s) will be used as a result. Based on the result of the game, the agents will change their policy on whether they accept the immigrant or host culture. The agents preference or probability of choosing a particular game will change over time, because the agents are given an ability to learn and add a preference for a particular game. The more often that a game is selected, the more likely it will be chosen in the future by the deciding agent.

## HOW TO USE IT

On the interface tab, there are two sliders that will create the initial number of turtles. The initial_eu_number slider will indicate how many european turtles are created on setup, and the initial_immigrants_number slider will indicate how many immigrant turtles are created on setup. The colors of these turtles can be altered and the colors will change on setup. The user may change the colors by clicking on eu_color or im_color and changing the color of the european and immigrant turtles respectively. The search-area slider can also be used to adjust the turtles search radius when they are looking for a second player to their game. The larger the search area, the more likely that the turtle will find a turtle to play against. The user can also adjust the probabilities or percentages of choosing a particular game. It is important to note that these probabilities or percentages must add up to 100 or the simulation will automatically set percentages to 20 each. It is also important to note that these values will change for each agent as the ticks progress through the simulation.

## THINGS TO NOTICE

User(s) should notice that no matter how many agents are added to the model, the number of agents favoring the host culture and the number of agents supporting the immigrant culture will always teeter around the fifty percent line if the percentages are left to the default 20 percent each. Depending on the percentages, it is possible to observe each culture completely take over and control the population.

## THINGS TO TRY

Try moving the sliders that initialize the model with different numbers of agents including the initial immigrants and european numbers. The search area can be adjusted while the model is executing. In order for the results to be noticed as the search area is altered, try setting the initial immigrants and european numbers very low. You may also wish to slow down the execution speed in order to be sure to notice the differences. Try altering the percentages in order to observe different scenarios. It is important to note that the user will also see different results even leaving all of the values the same between different runs of the simulation.

## EXTENDING THE MODEL

1. Modify the move procedure to accept a parameter that will allow agents of different agent sets to move at different speeds. After altering the move procedure, modify the go procedure to ensure that the agents move at different speeds by passing the parameter to the move function based on the agent type. 

2. The user can add new game theory techniques to the model. In fact, there is a comment in the code section that indicates where the new techniques may be added.

3. The user can alter the number of preset game theory techniques by rearranging the order or decrementing the number of possible techniques.

4. The user should add a measure of the average number of agents supporting each culture for a given amount of time. For example, keep track of the numbers over a period of 100 ticks. If the average number of supporters for the European culture is within a tolerance level of the current value, then the simulation has reached a steady state. 

## NETLOGO FEATURES

The one-of procedure was particularly useful in order to obtain a second player to the game. In combination with the in-radius procedure we were able to attempt to pick out a target.

Usually the ask command is used with the set of turtles or patches, but in our case we used ask with a specific target in order to change the variables for that specific turtle without ever knowing the turtle number or id.

The nobody keyword was also used in order to ensure that there was actually a turtle found that met the search criteria. The nobody keyword was used as a safeguard, because when no turtle was found errors could occur.

## RELATED MODELS

All Prisoner's Dilemma models under the Social Science portion of the model library. The models include: PD Basic, PD Basic Evolutionary, PD N-Person Iterated, and PD Two Person Iterated.

The segregation model. These models are related, because this model uses the idea that people want to be near people with the same characteristics. In our model, immigrants or europeans are influenced by the percentage of agents in the model.

## CREDITS AND REFERENCES

Erich Prisner, Game Theory through Examples (Washington, DC: The Mathematical Association of America, 2014), 16.

Herbert Gintis, Game Theory Evolving: A Problem-Centered Introduction to Modeling Strategic Behavior (Princeton, N.J.: Princeton University Press, ©2000), 148.

Rafaela M. Dancygier and David D. Laitin, “Immigration Into Europe: Economic Discrimination, Violence, and Public Policy,” Annual Review of Political Science (January 17, 2014).

Shahrabi M. Farahani and M. Sheikhmohammady, “A Review On Symmetric Games: Theory, Comparison and Applications,” International Journal of Applied Operational Research 4, no. 3 (Summer 2014).

Stephen J. DeCanio and Anders Fremstad, “Game Theory and Climate Diplomacy,” Ecological Economics 85 (2013).

Tim Büthe, “Basic Games,” Duke University.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
