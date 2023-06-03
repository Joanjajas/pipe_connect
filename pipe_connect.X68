*-----------------------------------------------------------
* Title      : Pipe Connect
* Written by : Jose Abad Martinez y Joan Beltran Peris
* Date       :
* Description:
*-----------------------------------------------------------
    
    ORG 25*4
    DC.L CRONOMETER
    
    ORG    $1000

******************************** CONSTANTES *****************************************

SCREEN_WIDTH  EQU 640 ; Anchura de la pantalla en pixeles
SCREEN_HEIGHT EQU 690 ; Altura de la pantalla en pixeles

* Colores
WHITE        EQU $00FFFFFF
BLACK        EQU $00000000
OLIVE        EQU $00008080
BROWN        EQU $00003366
CYAN         EQU $00FFFF00
GRAY         EQU $00808080
FUCHSIA      EQU $00FF00FF
ORANGE       EQU $000055FF
YELLOW       EQU $0000FFFF
BLUE         EQU $00FF0000
GREEN        EQU $0000FF00
RED          EQU $000000FF
SOFT_OLIVE   EQU $00003030
SOFT_BROWN   EQU $00001144
SOFT_CYAN    EQU $00555500
SOFT_FUCHSIA EQU $00550055
SOFT_GRAY    EQU $00303030
SOFT_ORANGE  EQU $000050AA
SOFT_YELLOW  EQU $00007777
SOFT_BLUE    EQU $00550000
SOFT_GREEN   EQU $00005500
SOFT_RED     EQU $00000099
BACKGROUND   EQU $00111111
BORDER_COLOR EQU $00000000


******************************** MACROS *****************************************

* Macro para establecer la resolucion de la pantalla en pixeles (ver TRAP #33)
* \1: Anchura de la pantalla en pixeles
* \2: Altura de la pantalla en pixeles
SET_SCREEN_RESOLUTION MACRO
    MOVE.B #33,D0
    MOVE.L \1*$10000,D1
    ADD.L  \2,D1
    TRAP   #15
    ENDM

* Macro para generar un delay de n/100 segundos (ver TRAP #23)
* \1: n
DELAY MACRO
    MOVE.L #23,D0
    MOVE.L \1,D1
    TRAP #15
    ENDM

* Macro para reproducir un sonido (ver TRAP #73)
* \1: Nombre del archivo a reproducir (tiene que estar en la misma carpeta que el codigo fuente)
PLAY_SOUND MACRO
    MOVE.L #73,D0
    MOVE.L \1,A1
    TRAP #15
    ENDM

* Macro para establecer el valor de las variables necesarias al seleccionar un nivel
* \1: Numero de filas que tendra el tablero
* \2: Numero de columnas que tendra el tablero
* \3: Numero total de posibles conexiones del nivel
SET_LEVEL_VARIABLES MACRO
    MOVE.W \1,ROWS              ; Movemos el numero de filas que tendra el tablero a la variable ROWS
    MOVE.W \2,COLUMNS           ; Movemos el numero de columnas que tendra el tablero a la variable COLUMNS

    MOVE.L #SCREEN_WIDTH,D0     ; Movemos el valor de la anchura de la pantalla a D0
    DIVU COLUMNS,D0             ; Dividimos la anchura de la pantalla por el numero de columnas del tablero
    MOVE.W D0,CELL_WIDTH        ; Movemos el resultado a la variable CELL_WIDTH

    MOVE.L #SCREEN_HEIGHT-50,D0 ; Movemos el valor de la altura de la pantalla a D0 restandole 70 para que el tablero quede de forma adecuada
    DIVU ROWS,D0                ; Dividimos la altura de la pantalla por el numero de filas del tablero
    MOVE.W D0,CELL_HEIGHT       ; Movemos el resultado a la variable CELL_HEIGHT

    MOVE.B \3,TOTAL_CONNECTIONS ; Pasamos el numero total de posibles conexiones del nivel a la variable TOTAL_CONNECTIONS
    CLR.B COMPLETED_CONNECTIONS ; Reseteamos el numero de conexiones completadas
    
    MOVE.B #0,SECONDS           ; Reseteamos los segundos del cronometro
    MOVE.B #0,MINUTES           ; Reseteamos los minutos del cronometro
    MOVE.B #0,DIGIT_0           ; Ponemos el primer digito de los minutos de cronometro a 0
    MOVE.B #0,DIGIT_1           ; Ponemos el segundo digito de los minutos de cronometro a 0

    * Limpiamos la pantalla (ver TRAP #11)
    MOVE.L #11,D0
    MOVE.W #$FF00,D1
    TRAP #15
    ENDM

* Macro para establecer el color de dibujado (ver TRAP #80)
* \1: Color
SET_PEN_COLOR MACRO
    MOVE.L #80,D0
    MOVE.L \1,D1
    TRAP   #15
    ENDM

* Macro para establecer el color de rellenado (ver TRAP #81)
* \1: Color
SET_FILL_COLOR MACRO
    MOVE.L #81,D0
    MOVE.L \1,D1
    TRAP   #15
    ENDM

* Macro para dibujar una figura en pantalla (ver TRAP #87,#88,#90,#91)
* \1: Coordenada X
* \2: Coordenada Y
* \3: Anchura de la figura
* \4: Altura de la figura
* \5: Figura a dibujar (ej. #90: Rectangulo sin color de relleno)
DRAW_FIGURE MACRO
    MOVE.W  \1,D1 ; Coordenada X de la figura
    MOVE.W  \2,D2 ; Coordenada Y de la figura

    MOVE.W  \1,D3
    ADD.W   \3,D3 ; Coordenada X2 de la figura (X + anchura)

    MOVE.W  \2,D4
    ADD.W   \4,D4 ; Coordenada Y2 de la figura (Y + altura)

    MOVE.L  \5,D0 ; Establecemos la figura a dibujar
    TRAP    #15
    ENDM

* Macro para calcular la posicion de una celda del tablero en pantalla, en pixeles
* \1: Fila del tablero en la que esta la celda
* \2: Columna del tablero en la que esta la celda
GET_CELL_POSITION MACRO
    MOVE.W \2,D0        ; Movemos la columna en la que esta la celda a D0
    MULU CELL_WIDTH,D0  ; Multiplicamos el numero de columna en la que esta la celda por la anchura de una celda
    MOVE.W D0,CELL_X    : Movemos el resultado a la variable CELL_X

    MOVE.W \1,D0        ; Movemos la fila en la que eesta la celda a D0
    MULU CELL_HEIGHT,D0 ; Multiplicamos el numero de fila en la que esta la celda por la altura de una celda
    MOVE.W D0,CELL_Y    ; Movemos el resultado a la variable CELL_Y
    ENDM

* Macro para seleccionar el tipo de celda de una determinada posicion del tablero
* \1: Fila del tablero donde esta la celda
* \2: Columna del tablero donde esta la celda
GET_CELL MACRO
    MOVE.W \1,D0                 ; Movemos la fila en la que esta la celda al registro D0
    MULU COLUMNS,D0              ; Multiplicamos por el numero de celdas que hay en cada fila
    ADD.W \2,D0                  ; Sumamos la columna en la que esta la celda
    MOVE.B (A0,D0),SELECTED_CELL ; Movemos el valor de la celda a la variable SELECTED_CELL
    ENDM

* Macro para cambiar el tipo de celda de una determinada posicion del tablero
* \1: Fila del tablero donde esta la celda
* \2: Columna del tablero donde esta la celda
* \3: Tipo de celda que va a quedar en esa posicion del tablero
SET_CELL MACRO
    MOVE.W \1,D0      ; Movemos la fila en la que esta la celda al registro D0
    MULU COLUMNS,D0   ; Multiplicamos por el numero de celdas que hay en cada fila
    ADD.W \2,D0       ; Sumamos la columna en la que esta la celda
    MOVE.B \3,(A0,D0) ; Movemos el valor de la celda que queremos establecer a la correspondiente posicion del tablero
    ENDM

* Macro para establecer el color de dibujado para dibujar celdas con el mouse
* \1: Color a establecer como color seleccionado
SET_DRAWING_COLOR MACRO
    MOVE.W CURSOR_ROW,LAST_DRAWED_CELL_ROW        ; Actualizamos el valor de la variable LAST_DRAWED_CELL_ROW
    MOVE.W CURSOR_COLUMN,LAST_DRAWED_CELL_COLUMN  ; Actualizamos el valor de la variable LAST_DRAWED_CELL_COLUMN

    MOVE.W CURSOR_ROW,LAST_ROUNDED_CELL_ROW       ; Actualizamos el valor de la variable LAST_ROUNDED_CELL_ROW
    MOVE.W CURSOR_COLUMN,LAST_ROUNDED_CELL_COLUMN ; Actualizamos el valor de la variable LAST_ROUNDED_CELL_COLUMN

    MOVE.B \1,DRAWING_COLOR                       ; Establecemos el color de dibujado moviendolo a la variable DRAWING_COLOR

    CLR ROW_COUNT                                 ; Reseteamos la cuenta de las filas
    CLR COLUMN_COUNT                              ; Reseteamos la cuenta de las columnas
    JSR DELETE_EXISTING_CONNECTION                ; Eliminamos la conexion previamente realizada, si existe, iterando sobre las filas y columnas del tablero

    ENDM

* Macro para eliminar un color del tablero de juego
* \1: Color a eliminar del tablero
DELETE_COLOR MACRO
    MOVE.B \1,COLOR_TO_DELETE ; Movemos el color a eliminar a la variable COLOR_TO_DELETE

    CLR.W ROW_COUNT         ; Reseteamos la cuenta de las filas
    CLR.W COLUMN_COUNT      ; Reseteamos la cuenta de las columnas

    CLR ROW_COUNT           ; Reseteamos la cuenta de las filas
    CLR COLUMN_COUNT        ; Reseteamos la cuenta de las columnas

    JSR DELETE_BOARD_COLOR ; Saltamos a la subrutina encargada de eliminar el color iterando todas las filas y columnas del tablero
    ENDM

* Subrutina para dibujar una celda eliptica en una posicion del tablero
* \1: Fila del tablero donde dibujar la celda
* \2: Columna del tablero donde dibujar la celda
* \3: Color de la elipse
* \4: Color del fondo de la celda
DRAW_ROUNDED_CELL MACRO
    GET_CELL_POSITION \1,\2             ; Obtenemos la posicion de la celda en la pantalla

    ADD.W #1,CELL_X                     ; Añadimos 1 a la posicion X para separar el rectangulo de los bordes
    ADD.W #1,CELL_Y                     ; Añadimos 1 a la posicion Y para separar el rectangulo de los bordes

    MOVE.W CELL_WIDTH,D5                ; Movemos la anchura de la celda a D5
    MOVE.W CELL_HEIGHT,D6               ; Movemos la altura de la celda a D6

    SUB.W #2,D5                         ; Restamos 2 a la anchura de la celda para separarla de los bordes
    SUB.W #2,D6                         ; Restamos 2 a la altura de la celda para separarla de los bordes

    SET_PEN_COLOR #BORDER_COLOR         ; Establecemos el color para el borde del rectangulo
    SET_FILL_COLOR \4                   ; Establecemos el color para el relleno del rectangulo
    DRAW_FIGURE CELL_X,CELL_Y,D5,D6,#87 ; Dibujamos el rectangulo

    ADD.W #5,CELL_X                     ; Añadimos 5 a la posicion X para separar la elipse de los bordes
    ADD.W #5,CELL_Y                     ; Añadimos 5 a la posicion Y para separar la elipse de los bordes

    MOVE.W CELL_WIDTH,D5                ; Movemos la anchura de la celda a D5
    MOVE.W CELL_HEIGHT,D6               ; Movemos la altura de la celda a D6

    SUB.W #10,D5                        ; Restamos 10 a la anchura de la celda para separarla de los bordes
    SUB.W #10,D6                        ; Restamos 10 a la altura de la celda para separarla de los bordes

    SET_PEN_COLOR \3                    ; Establecemos el color para el borde de la elipse
    SET_FILL_COLOR \3                   ; Establecemos el color para el relleno de la elipse
    DRAW_FIGURE CELL_X,CELL_Y,D5,D6,#88 ; Dibujamos la elipse
    ENDM

* Subrutina para dibujar una celda rectangular en una posicion del tablero
* \1: Fila del tablero donde esta la celda
* \2: Columna del tablero donde esta la celda
* \3: Color del rectangulo
DRAW_NORMAL_CELL MACRO
    GET_CELL_POSITION \1,\2             ; Obtenemos la posicion de la celda en la pantalla

    ADD.W #1,CELL_X                     ; Añadimos 1 a la posicion X para separar el rectangulo de los bordes
    ADD.W #1,CELL_Y                     ; Añadimos 1 a la posicion Y para separar el rectangulo de los bordes

    SET_PEN_COLOR #BORDER_COLOR         ; Establecemos el color para el borde
    SET_FILL_COLOR \3                   ; Establecemos el color para el relleno

    MOVE.W CELL_WIDTH,D5                ; Movemos la anchura de la celda a D5
    MOVE.W CELL_HEIGHT,D6               ; Movemos la altura de la celda a D6

    SUB.W #2,D5                         ; Restamos 2 a la anchura de la celda para separarla de los bordes
    SUB.W #2,D6                         ; Restamos 2 a la altura de la celda para separarla de los bordes

    DRAW_FIGURE CELL_X,CELL_Y,D5,D6,#87 ; Dibujamos el rectangulo
    ENDM


******************************** INICIO DEL PROGRAMA *****************************************


START:
    SET_SCREEN_RESOLUTION #SCREEN_WIDTH,#SCREEN_HEIGHT ; Establecemos la resolucion de la pantalla en pixeles
    JSR ENABLE_EXCEPTIONS                              ; Habilitamos las exepciones para que funcione el cronometro
    JMP SELECT_LEVEL                                   ; Seleccionamos un nivel

ENABLE_EXCEPTIONS
    * Habilitamos las exepciones (ver TRAP #35)
    MOVE.B #32,D0
    MOVE.B #05,D1
    TRAP #15

    MOVE.B #06,D1   ; Habilitamos Auto IRQ
    MOVE.B #129,D2  ; Habilitamos el IRQ individual del bit 0
    MOVE.L #1000,D3 ; Establecemos el intervalo en 1 segundo
    TRAP #15

    RTS


******************************** SELECCION DE NIVEL *****************************************


* Subrutina encargada de pedirle al usuario que seleccione un nivel del juego
SELECT_LEVEL
    * Limpiamos la pantalla (ver TRAP #11)
    MOVE.L #11,D0
    MOVE.W #$FF00,D1
    TRAP #15

    SET_FILL_COLOR #BLACK ; Color de fondo del texto

    * Establecemos la fuente y el tamaño del texto (ver TRAP #21)
    MOVE.L #21,D0
    MOVE.L #$0000FF00,D1
    MOVE.L #$06120001,D2
    TRAP #15

    * Mostramos un mensaje para seleccionar un nivel por pantalla (ver TRAP #14)
    MOVE.L #14,D0
    MOVE.L #SELECT_LEVEL_MESSAGE,A1
    TRAP #15

    * Leemos la eleccion del usuario (ver TRAP #4)
    MOVE.L #4,D0
    TRAP #15

    MOVE.B D1,LEVEL ; Movemos la eleccion del usuario a la variable LEVEL
    JMP SET_LEVEL   ; Saltamos a la subturina encargada de establecer el nivel correspondiente

* Subrutina encargada de establecer un nivel en funcion de la eleccion del usuario
SET_LEVEL
    * Nivel 1
    CMP.B #$01,LEVEL
    BEQ SET_LEVEL_1

    * Nivel 2
    CMP.B #$02,LEVEL
    BEQ SET_LEVEL_2

    * Nivel 3
    CMP.B #$03,LEVEL
    BEQ SET_LEVEL_3

    * Nivel 4
    CMP.B #$04,LEVEL
    BEQ SET_LEVEL_4

    JMP SELECT_LEVEL ; Si no se elige un nivel correctamente volvemos a pedirselo al usuario

* Subrutina para establecer el nivel 1
SET_LEVEL_1
    SET_LEVEL_VARIABLES #5,#5,#4    ; Calculamos el valor de las variables del tablero
    MOVE.L #TABLERO_LVL_1,A0        ; Movemos el tablero a A0
    JMP MAIN_LOOP                   ; Saltamos al loop principal

* Subrutina para establecer el nivel 2
SET_LEVEL_2
    SET_LEVEL_VARIABLES #5,#5,#5    ; Calculamos el valor de las variables del tablero
    MOVE.L #TABLERO_LVL_2,A0        ; Movemos el tablero a A0
    JMP MAIN_LOOP                   ; Saltamos al loop principal

* Subrutina para establecer el nivel 3
SET_LEVEL_3
    SET_LEVEL_VARIABLES #8,#8,#9    ; Calculamos el valor de las variables del tablero
    MOVE.L #TABLERO_LVL_3,A0        ; Movemos el tablero a A0
    JMP MAIN_LOOP                   ; Saltamos al loop principal

* Subrutina para establecer el nivel 4
SET_LEVEL_4
    SET_LEVEL_VARIABLES #10,#10,#10 ; Calculamos el valor de las variables del tablero
    MOVE.L #TABLERO_LVL_4,A0        ; Movemos el tablero a A0
    JMP MAIN_LOOP                   ; Saltamos al loop principal


******************************** LOOP PRINCIPAL *****************************************


* Loop principal del juego
MAIN_LOOP
    JSR UPDATE_BOARD      ; Actualizamos el estado del tablero
    JSR DRAW_BOARD        ; Dibujamos el tablero de juego en pantalla
    JSR UPDATE_CRONOMETER ; Actualizamos el valor del cronometro
    JSR DRAW_LEVEL_INFO   ; Dibujamos la informacion sobre el nivel que se mostrara en la parte inferior de la pantalla
    JSR CHECK_VICTORY     ; Comprobamos si se ha completado el nivel
    JMP MAIN_LOOP         ; Volvemos al loop principal


******************************** ACTUALIZACION CRONOMETRO *****************************************


* Subrutina para actualizar el valor del cronometro
UPDATE_CRONOMETER
    * Primer digito de los segundos
    MOVE.B SECONDS,D0
    DIVU #10,D0
    MOVE.B D0,DIGIT_2

    * Segundo digito de los segundos
    SWAP.W D0
    MOVE.B D0,DIGIT_3
    
    CLR.L D0    
    CMP.B #60,SECONDS  ; Comprobamos si se ha completado un minuto
    BEQ ADD_MINUTE     ; En ese caso actualizamos la cuenta de los minutos del cronometro

    RTS

* Subrutina para actualizar el valor de la cuenta de los minutos del cronometro
ADD_MINUTE
    ADD.B #1,MINUTES   ; Añadimos 1 a la cuenta de los minutos
    MOVE.B #0,SECONDS  ; Reseteamos la cuenta de los segundos

    * Primer digito de los minutos
    MOVE.B MINUTES,D0
    DIVU #10,D0
    MOVE.B D0,DIGIT_0

    * Segundo digito de los minutos
    SWAP.W D0
    MOVE.B D0,DIGIT_1

    RTS


******************************** DIBUJADO INFORMACION DEL NIVEL *****************************************


* Subrutina que se encarga de dar informacion extra al jugador como el tiempo que lleva jugando
* en un nivel mediante un cronometro y el número de conexiones que llevas realizadas asi como el
* nivel que se esta jugando.
DRAW_LEVEL_INFO
    SET_FILL_COLOR #BLACK            ; Establecemos el color de fondo del texto

    * Establecemos la fuente y el tamaño del texto (ver TRAP #21)
    MOVE.L #21,D0
    MOVE.L #$0000FF00,D1
    MOVE.L #$06120001,D2
    TRAP #15

    * Mostramos en pantalla el texto sobre el nivel que se esta jugando (ver TRAP #95)
    MOVE.L #95,D0
    MOVE.L #LEVEL_TEXT,A1
    MOVE.L #10,D1                    ; Posicion X del texto
    MOVE.L #SCREEN_HEIGHT-40,D2      ; Posicion Y del texto 
    TRAP #15

    * Mostramos en pantalla el nivel que se esta jugando (ver TRAP #95)
    MOVE.L #95,D0
    MOVE.L #LEVEL,A1
    ADD.B #48,(A1)                   ; Sumamos 48 para representar el numero en ascii
    MOVE.L #90,D1                    ; Posicion X del texto
    MOVE.L #SCREEN_HEIGHT-40,D2      ; Posicion Y del texto
    TRAP #15
    SUB.B #48,(A1)                   ; Restamos 48 para dejar el valor igual que estaba antes de ser representado
    
    * Mostramos en pantalla el cronometro primer digito del cronometro (ver TRAP #95)
    MOVE.L #95,D0
    MOVE.L #DIGIT_0,A1
    ADD.B #48,(A1)                   ; Sumamos 48 para representar el numero en ascii
    MOVE.L #SCREEN_WIDTH/2-70,D1     ; Posicion X del digito
    MOVE.L #SCREEN_HEIGHT-40,D2      ; Posicion Y del digito
    TRAP #15
    SUB.B #48,(A1)                   ; Restamos 48 para dejar el valor igual que estaba antes de ser representado
    
    * Mostramos en pantalla el segundo digito del cronometro (ver TRAP #95)
    MOVE.L #95,D0
    MOVE.L #DIGIT_1,A1
    ADD.B #48,(A1)                   ; Sumamos 48 para representar el numero en ascii
    MOVE.L #SCREEN_WIDTH/2-50,D1     ; Posicion X del digito
    MOVE.L #SCREEN_HEIGHT-40,D2      ; Posicion Y del digito
    TRAP #15
    SUB.B #48,(A1)                   ; Restamos 48 para dejar el valor igual que estaba antes de ser representado
    
    * Mostramos en pantalla la separacion entre minutos y segundos del cronometro (ver TRAP #95)
    MOVE.L #95,D0
    MOVE.L #COLON,A1
    MOVE.L #SCREEN_WIDTH/2-30,D1     ; Posicion X del texto
    MOVE.L #SCREEN_HEIGHT-40,D2      ; Posicion Y del texto
    TRAP #15
   
    * Mostramos en pantalla el tercer digito del cronometro (ver TRAP #95)
    MOVE.L #95,D0
    MOVE.L #DIGIT_2,A1
    ADD.B #48,(A1)                   ; Sumamos 48 para representar el numero en ascii
    MOVE.L #SCREEN_WIDTH/2-10,D1     ; Posicion X del digito
    MOVE.L #SCREEN_HEIGHT-40,D2      ; Posicion Y del digito
    TRAP #15
    SUB.B #48,(A1)                   ; Restamos 48 para dejar el valor igual que estaba antes de ser representado

    * Mostramos en pantalla el cuarto digito del cronometro (ver TRAP #95)
    MOVE.L #95,D0
    MOVE.L #DIGIT_3,A1
    ADD.B #48,(A1)                   ; Sumamos 48 para representar el numero en ascii
    MOVE.L #SCREEN_WIDTH/2+10,D1     ; Posicion X del digito
    MOVE.L #SCREEN_HEIGHT-40,D2      ; Posicion Y del digito
    TRAP #15
    SUB.B #48,(A1)                   ; Restamos 48 para dejar el valor igual que estaba antes de ser representado

    * Mostramos en pantalla el texto sobre las conexiones realizadas (ver TRAP #95)
    MOVE.L #95,D0
    MOVE.L #CONNECTIONS_TEXT,A1
    MOVE.L #SCREEN_WIDTH-165,D1      ; Posicion X del texto
    MOVE.L #SCREEN_HEIGHT-40,D2      ; Posicion Y del texto 
    TRAP #15

    * Mostramos en pantalla el numero de conexiones realizadas (ver TRAP #95)
    MOVE.L #95,D0
    MOVE.L #COMPLETED_CONNECTIONS,A1
    ADD.B #48,(A1)                   ; Sumamos 48 para representar el numero en ascii
    MOVE.L #SCREEN_WIDTH-20,D1       ; Posicion X del texto
    MOVE.L #SCREEN_HEIGHT-40,D2      ; Posicion Y del texto
    TRAP #15
    SUB.B #48,(A1)                   ; Restamos 48 para dejar el valor igual que estaba antes de ser representado

    RTS


******************************** DIBUJADO DEL TABLERO *****************************************


* Subrutina que dibuja el tablero de juego.
* Itera fila por fila dibujando cada celda en funcion la informacion del tablero
* La variable ROW_COUNT lleva la cuenta de las filas y la variable COLUMN_COUNT de las columnas
DRAW_BOARD
    CLR.W ROW_COUNT     ; Reseteamos la cuenta de las filas
    CLR.W COLUMN_COUNT  ; Reseteamos la cuenta de las columnas
    JSR DRAW_BOARD_ROWS
    RTS                 ; Volvemos al loop principal

* Subrutina para iterar sobre las filas del tablero
DRAW_BOARD_ROWS
    MOVE.W ROW_COUNT,D0
    CMP.W ROWS,D0       ; Comprobamos si hemos llegado a la ultima fila
    BGE JUMP_BACK

    CLR.W COLUMN_COUNT  ; Reseteamos la cuenta de las columnas
    JSR DRAW_BOARD_CELL ; Dibujamos la fila

    ADD.W #1,ROW_COUNT  ; A?adimos 1 a la cuenta de filas
    JMP DRAW_BOARD_ROWS ; Seguimos iterando filas

* Subrutina para dibujar filas del tablero
DRAW_BOARD_CELL
    MOVE.W COLUMN_COUNT,D0
    CMP.W COLUMNS,D0       ; Comprobamos si hemos llegado a la ultima columna
    BGE JUMP_BACK

    JSR DRAW_CELL          ; Dibujamos la celda

    ADD.W #1,COLUMN_COUNT  ; A?adimos 1 a la cuenta de las columnas
    JMP DRAW_BOARD_CELL    ; Seguimos dibujando celdas

* Subrutina para dibujar una celda del tablero en funcion de su color
DRAW_CELL
    GET_CELL ROW_COUNT,COLUMN_COUNT ; Seleccionamos la celda a dibujar

    * Celda redonda oliva
    CMP.B #$8A,SELECTED_CELL
    BEQ DRAW_OLIVE_ROUNDED_CELL

    * Celda redonda gris
    CMP.B #$89,SELECTED_CELL
    BEQ DRAW_GRAY_ROUNDED_CELL

    * Celda redonda cián
    CMP.B #$88,SELECTED_CELL
    BEQ DRAW_CYAN_ROUNDED_CELL

    * Celda redonda fucsia
    CMP.B #$87,SELECTED_CELL
    BEQ DRAW_FUCHSIA_ROUNDED_CELL

    * Celda redonda marrón
    CMP.B #$86,SELECTED_CELL
    BEQ DRAW_BROWN_ROUNDED_CELL

    * Celda redonda naranja
    CMP.B #$85,SELECTED_CELL
    BEQ DRAW_ORANGE_ROUNDED_CELL

    * Celda redonda amarilla
    CMP.B #$84,SELECTED_CELL
    BEQ DRAW_YELLOW_ROUNDED_CELL

    * Celda redonda azul
    CMP.B #$83,SELECTED_CELL
    BEQ DRAW_BLUE_ROUNDED_CELL

    * Celda redonda verde
    CMP.B #$82,SELECTED_CELL
    BEQ DRAW_GREEN_ROUNDED_CELL

    * Celda redonda roja
    CMP.B #$81,SELECTED_CELL
    BEQ DRAW_RED_ROUNDED_CELL

    * Celda rectangular oliva
    CMP.B #$0A,SELECTED_CELL
    BEQ DRAW_OLIVE_NORMAL_CELL

    * Celda rectangular gris
    CMP.B #$09,SELECTED_CELL
    BEQ DRAW_GRAY_NORMAL_CELL

    * Celda rectangular cián
    CMP.B #$08,SELECTED_CELL
    BEQ DRAW_CYAN_NORMAL_CELL

    * Celda rectangular fucsia
    CMP.B #$07,SELECTED_CELL
    BEQ DRAW_FUCHSIA_NORMAL_CELL

    * Celda rectangular marrón
    CMP.B #$06,SELECTED_CELL
    BEQ DRAW_BROWN_NORMAL_CELL

    * Celda ractangular naranja
    CMP.B #$05,SELECTED_CELL
    BEQ DRAW_ORANGE_NORMAL_CELL

    * Celda rectangular amarilla
    CMP.B #$04,SELECTED_CELL
    BEQ DRAW_YELLOW_NORMAL_CELL

    * Celda rectangular azul
    CMP.B #$03,SELECTED_CELL
    BEQ DRAW_BLUE_NORMAL_CELL

    * Celda rectangular verde
    CMP.B #$02,SELECTED_CELL
    BEQ DRAW_GREEN_NORMAL_CELL

    * Celda rectangular roja
    CMP.B #$01,SELECTED_CELL
    BEQ DRAW_RED_NORMAL_CELL

    * Celda vacia
    CMP.B #$00,SELECTED_CELL
    BEQ DRAW_EMPTY_CELL

    RTS

* Subrutina para dibujar una celda redonda oliva
DRAW_OLIVE_ROUNDED_CELL
    DRAW_ROUNDED_CELL ROW_COUNT,COLUMN_COUNT,#OLIVE,#SOFT_OLIVE
    RTS

* Subrutina para dibujar una celda redonda gris
DRAW_GRAY_ROUNDED_CELL
    DRAW_ROUNDED_CELL ROW_COUNT,COLUMN_COUNT,#GRAY,#SOFT_GRAY
    RTS

* Subrutina para dibujar una celda redonda cián
DRAW_CYAN_ROUNDED_CELL
    DRAW_ROUNDED_CELL ROW_COUNT,COLUMN_COUNT,#CYAN,#SOFT_CYAN
    RTS

* Subrutina para dibujar una celda redonda fucsia
DRAW_FUCHSIA_ROUNDED_CELL
    DRAW_ROUNDED_CELL ROW_COUNT,COLUMN_COUNT,#FUCHSIA,#SOFT_FUCHSIA
    RTS

* Subrutina para dibujar una celda redonda marrón
DRAW_BROWN_ROUNDED_CELL
    DRAW_ROUNDED_CELL ROW_COUNT,COLUMN_COUNT,#BROWN,#SOFT_BROWN
    RTS

* Subrutina para dibujar una celda redonda naranja
DRAW_ORANGE_ROUNDED_CELL
    DRAW_ROUNDED_CELL ROW_COUNT,COLUMN_COUNT,#ORANGE,#SOFT_ORANGE
    RTS

* Subrutina para dibujar una celda redonda amarilla
DRAW_YELLOW_ROUNDED_CELL
    DRAW_ROUNDED_CELL ROW_COUNT,COLUMN_COUNT,#YELLOW,#SOFT_YELLOW
    RTS

* Subrutina para dibujar una celda redonda azul
DRAW_BLUE_ROUNDED_CELL
    DRAW_ROUNDED_CELL ROW_COUNT,COLUMN_COUNT,#BLUE,#SOFT_BLUE
    RTS

* Subrutina para dibujar una celda redonda verde
DRAW_GREEN_ROUNDED_CELL
    DRAW_ROUNDED_CELL ROW_COUNT,COLUMN_COUNT,#GREEN,#SOFT_GREEN
    RTS

* Subrutina para dibujar una celda redonda roja
DRAW_RED_ROUNDED_CELL
    DRAW_ROUNDED_CELL ROW_COUNT,COLUMN_COUNT,#RED,#SOFT_RED
    RTS

* Subrutina para dibujar una celda rectangular oliva
DRAW_OLIVE_NORMAL_CELL
    DRAW_NORMAL_CELL ROW_COUNT,COLUMN_COUNT,#SOFT_OLIVE
    RTS

* Subrutina para dibujar una celda rectangular gris
DRAW_GRAY_NORMAL_CELL
    DRAW_NORMAL_CELL ROW_COUNT,COLUMN_COUNT,#SOFT_GRAY
    RTS

* Subrutina para dibujar una celda rectangular cián
DRAW_CYAN_NORMAL_CELL
    DRAW_NORMAL_CELL ROW_COUNT,COLUMN_COUNT,#SOFT_CYAN
    RTS

* Subrutina para dibujar una celda rectangular fucsia
DRAW_FUCHSIA_NORMAL_CELL
    DRAW_NORMAL_CELL ROW_COUNT,COLUMN_COUNT,#SOFT_FUCHSIA
    RTS

* Subrutina para dibujar una celda rectangular marrón
DRAW_BROWN_NORMAL_CELL
    DRAW_NORMAL_CELL ROW_COUNT,COLUMN_COUNT,#SOFT_BROWN
    RTS

* Subrutina para dibujar una celda rectangular naranja
DRAW_ORANGE_NORMAL_CELL
    DRAW_NORMAL_CELL ROW_COUNT,COLUMN_COUNT,#SOFT_ORANGE
    RTS

* Subrutina para dibujar una celda rectangular amarilla
DRAW_YELLOW_NORMAL_CELL
    DRAW_NORMAL_CELL ROW_COUNT,COLUMN_COUNT,#SOFT_YELLOW
    RTS

* Subrutina para dibujar una celda rectangular azul
DRAW_BLUE_NORMAL_CELL
    DRAW_NORMAL_CELL ROW_COUNT,COLUMN_COUNT,#SOFT_BLUE
    RTS

* Subrutina para dibujar una rectangular celda verde
DRAW_GREEN_NORMAL_CELL
    DRAW_NORMAL_CELL ROW_COUNT,COLUMN_COUNT,#SOFT_GREEN
    RTS

* Subrutina para dibujar una celda rectangular roja
DRAW_RED_NORMAL_CELL
    DRAW_NORMAL_CELL ROW_COUNT,COLUMN_COUNT,#SOFT_RED
    RTS

* Subrutina para dibujar una celda vacia
DRAW_EMPTY_CELL
    DRAW_NORMAL_CELL ROW_COUNT,COLUMN_COUNT,#BACKGROUND
    RTS


******************************** GESTION DEL CURSOR *****************************************


* Subrutina para obtener la posicion del cursor sobre la pantalla
GET_CURSOR_POSITION
    * Obtenemos el estado actual del mouse (ver TRAP #61)
    MOVE.L #61,D0
    MOVE.L #0,D1
    TRAP   #15

    CLR.L D0                ; Reseteamos el registro D0

    MOVE.W D1,D0            ; Movemos la posicion Y del cursor al registro D0
    DIVU CELL_WIDTH,D0      ; Dividimos la posicion Y del cursor por la altura de una celda
    MOVE.W D0,CURSOR_COLUMN ; Movemos el resultado a la variable CURSOR_ROW

    SWAP   D1               ; Intercambiamos la palabra mas alta con la mas baja en el registro
                            ; D0, ya que la instruccion trap #61 guarda la posicion X del cursor
                            ; en la palabra mas baja y la posicion Y en la mas alta

    CLR.L D0                ; Reseteamos el registro D0

    MOVE.W D1,D0            ; Movemos la posicion X del cursor al registro D0
    DIVU CELL_HEIGHT,D0     ; Dividimos la posicion X del cursor por la anchura de una celda
    MOVE.W D0,CURSOR_ROW    ; Movemos el resultado a la variable CURSOR_COLUMN

    
    MOVE.W ROWS,D0
    CMP.W CURSOR_ROW,D0
    BLS OUT_SCREEN

    MOVE.W COLUMNS,D0
    CMP.W CURSOR_COLUMN,D0
    BLS OUT_SCREEN

    RTS

* Subrutina para gestionar el caso en el que el cursor salga fuera del tablero
OUT_SCREEN
    DELETE_COLOR DRAWING_COLOR
    MOVE.B #0,UPDATE
    RTS

* Subrutina para obtener el tipo de celda situada debajo del cursor
GET_CELL_UNDER_CURSOR
    JSR GET_CURSOR_POSITION                ; Obtenemos la posicion del cursor sobre el tablero
    GET_CELL CURSOR_ROW,CURSOR_COLUMN      ; Seleccionamos la celda situada debajo del cursor
    MOVE.B SELECTED_CELL,CELL_UNDER_CURSOR ; Movemos el tipo de celda situada debajo del cursor a la variable CELL_UNDER_CURSOR
    RTS


******************************** ACTUALIZACION DEL TABLERO DE JUEGO *****************************************


* Subrutina para actualizar el estado del tablero de juego
UPDATE_BOARD
    * Obtenemos el estado actual del mouse (ver TRAP #61)
    MOVE.L #61,D0
    MOVE.L #0,D1
    TRAP #15

    CMP.B #$01,D0              ; Comprobamos si se esta pulsando el click izquierdo
    BEQ LEFT_CLICK_PRESSED

    MOVE.B #$01,UPDATE
    DELETE_COLOR DRAWING_COLOR ; Borramos todas las conexiones no completadas
    MOVE.B #$00,DRAWING_COLOR  ; Reseteamos el color de dibujado
    RTS

* Subrutina para comprobar el tipo de celda situada debajo del cursor
LEFT_CLICK_PRESSED
    CMP.B #$00,UPDATE            ; Comprobamos el valor de la flag UPDATE
    BEQ JUMP_BACK                ; Si la flag esta a 0 volvemos y no actualizamos el estado del tablero

    JSR GET_CELL_UNDER_CURSOR    ; Obtenemos el tipo de celda situada debajo del cursor

    * Celda redonda
    CMP.B #$80,CELL_UNDER_CURSOR
    BHI ROUNDED_CELL

    * Celda normal
    CMP.B #$80,CELL_UNDER_CURSOR
    BLS NORMAL_CELL

    RTS

* Subrutina para gestionar una celda redonda
ROUNDED_CELL
    CMP.B #$00,DRAWING_COLOR     ; Comprobamos si ya hay algun color de dibujado seleccionado
    BNE CHECK_CONNECTION         ; En el caso de que ya haya un color comprobamos si se ha realizado una conexion

    * Establecemos el color de dibujado
    * Celda redonda oliva
    CMP.B #$8A,CELL_UNDER_CURSOR
    BEQ SET_OLIVE_COLOR          ; Establecemos el color de dibujado a oliva

    * Celda redonda gris
    CMP.B #$89,CELL_UNDER_CURSOR
    BEQ SET_GRAY_COLOR           ; Establecemos el color de dibujado a gris

    * Celda redonda cián
    CMP.B #$88,CELL_UNDER_CURSOR
    BEQ SET_CYAN_COLOR           ; Establecemos el color de dibujado a cian

    * Celda redonda fucsia
    CMP.B #$87,CELL_UNDER_CURSOR
    BEQ SET_FUCHSIA_COLOR        ; Establecemos el color de dibujado a fucsia

    * Celda redonda marron
    CMP.B #$86,CELL_UNDER_CURSOR
    BEQ SET_BROWN_COLOR          ; Establecemos el color de dibujado a marron

    * Celda redonda naranja
    CMP.B #$85,CELL_UNDER_CURSOR
    BEQ SET_ORANGE_COLOR         ; Establecemos el color de dibujado a naranja

    * Celda redonda amarilla
    CMP.B #$84,CELL_UNDER_CURSOR
    BEQ SET_YELLOW_COLOR         ; Establecemos el color de dibujado a amarillo

    * Celda redonda azul
    CMP.B #$83,CELL_UNDER_CURSOR
    BEQ SET_BLUE_COLOR           ; Establecemos el color de dibujado a azul

    * Celda redonda verde
    CMP.B #$82,CELL_UNDER_CURSOR
    BEQ SET_GREEN_COLOR          ; Establecemos el color de dibujado a verde

    * Celda redonda roja
    CMP.B #$81,CELL_UNDER_CURSOR
    BEQ SET_RED_COLOR            ; Establecemos el color de dibujado a rojo

    RTS

* Subrutina para determinar si se ha realizado una conexion comparando el color de
* dibujado con el de la celda situada debajo del cursor
CHECK_CONNECTION
    JSR CHECK_DIAGONAL          ; Comprobamos si la conexion se ha realizado de forma legal

    CMP.B #$00,UPDATE           ; Si no se ha realizado de forma legal la variable UPDATE se pondra a 0
    BEQ JUMP_BACK

    MOVE.B CELL_UNDER_CURSOR,D0
    AND.B #15,D0                ; Obtenemos el color de la celda bajo el cursor

    CMP.B DRAWING_COLOR,D0
    BEQ CHECK_CONNECTION_POS    ; Si los colores coinciden pasamos a verificar la siguiente conexion

    DELETE_COLOR DRAWING_COLOR  ; Si no coinciden borramos el camino previamente realizado
    MOVE.B #$00,UPDATE
    RTS

* Subrutina para determinar si se ha realizado una conexion comparando la posicion inicial
* de la celda redonda seleccionada y la posicion de la celda bajo el cursor
CHECK_CONNECTION_POS
    MOVE.W CURSOR_ROW,D0              ; Movemos el valor de la fila donde esta el cursor a D0
    MOVE.W CURSOR_COLUMN,D1           ; Movemos el valor de la columna donde esta el cursor a D0

    CMP.W LAST_ROUNDED_CELL_ROW,D0    ; Comprobamos si la celda bajo el cursor esta en una fila distinta de la celda inicial
    BNE SET_CONNECTION                ; Si esta en una fila distinta significa que se ha realizado la conexion

    CMP.W LAST_ROUNDED_CELL_COLUMN,D1 ; Comprobamos si la celda bajo el cursor esta en una columna distinta de la celda inicial
    BNE SET_CONNECTION                ; Si esta en una columna distinta significa que se ha realizado la conexion

    DELETE_COLOR DRAWING_COLOR        ; Si no se ha realizado la conexion borramos el camino previamente realizado
    RTS

* Subrutina para establecer una conexion
SET_CONNECTION
    MOVE.B #$00,DRAWING_COLOR        ; Quitamos el color de dibujado para que no se borre la conexion realizada
    MOVE.B #$00,UPDATE               ; Ponemos la flag UPDATE a 0 para que deje de actualizarse el tablero
    ADD.B #1,COMPLETED_CONNECTIONS   ; Sumamos 1 al numero de conexion realizadas
    PLAY_SOUND #NEW_CONNECTION_SOUND ; Reproducimos un sonido
    RTS

* Subrutina para gestionar una celda normal
NORMAL_CELL
    JSR CHECK_DIAGONAL                 ; Comprobamos si no se ha realizado ningun movimiento ilegal en diagonal

    CMP.B #$00,UPDATE                  ; Si no se ha realizado de forma legal la variable UPDATE se pondra a 0
    BEQ JUMP_BACK

    CMP.B #$00,CELL_UNDER_CURSOR       ; Si la celda bajo el cursor es una celda vacia sin conlor, actualizamos su color
    BEQ UPDATE_CELL

    CMP.B #$00,DRAWING_COLOR           ; Si no hay ningun color de dibujado establecido volvemos y no hacemos nada
    BEQ JUMP_BACK

    MOVE.B CELL_UNDER_CURSOR,D0
    CMP.B DRAWING_COLOR,D0             ; Comparamos el color de la celda bajo el cursor con el color de dibujado
    BEQ JUMP_BACK                      ; Si son del mismo color volvemos y no hacemos nada

    * Si el color de la celda bajo el cursor y color de dibujado son distintos significa que nos hemos cruzado
    * con otro camino, por lo tanto eliminaremos ese camino y restaremos 1 al numero de conexiones realizadas
    SUB.B #1,COMPLETED_CONNECTIONS     ; Restamos 1 al numero de conexiones realizadas
    PLAY_SOUND #BREAK_CONNECTION_SOUND ; Reproducimos un sonido
    DELETE_COLOR CELL_UNDER_CURSOR     ; Eliminamos el camino con el que nos hemos cruzado
    RTS

* Subrutina para actualizar el estado de una celda en el tablero
UPDATE_CELL
    SET_CELL CURSOR_ROW,CURSOR_COLUMN,DRAWING_COLOR ; Cambiamos la celda situada debajo del cursor a una celda del color de dibujado
    MOVE.W CURSOR_COLUMN,LAST_DRAWED_CELL_COLUMN    ; Actualizamos el valor de la variable LAST_DRAWED_CELL_COLUMN
    MOVE.W CURSOR_ROW,LAST_DRAWED_CELL_ROW          ; Actualizamos el valor de la variable LAST_DRAWED_CELL_ROW
    RTS

* Subrutina para establecer el color seleccionado a oliva
SET_OLIVE_COLOR
    SET_DRAWING_COLOR #$0A
    RTS

* Subrutina para establecer el color seleccionado a gris
SET_GRAY_COLOR
    SET_DRAWING_COLOR #$09
    RTS

* Subrutina para establecer el color seleccionado a cian
SET_CYAN_COLOR
    SET_DRAWING_COLOR #$08
    RTS

* Subrutina para establecer el color seleccionado a fucsia
SET_FUCHSIA_COLOR
    SET_DRAWING_COLOR #$07
    RTS

* Subrutina para establecer el color seleccionado a marron
SET_BROWN_COLOR
    SET_DRAWING_COLOR #$06
    RTS

* Subrutina para establecer el color seleccionado a naranja
SET_ORANGE_COLOR
    SET_DRAWING_COLOR #$05
    RTS

* Subrutina para establecer el color seleccionado a amarillo
SET_YELLOW_COLOR
    SET_DRAWING_COLOR #$04
    RTS

* Subrutina para establecer el color seleccionado a azul
SET_BLUE_COLOR
    SET_DRAWING_COLOR #$03
    RTS

* Subrutina para establecer el color seleccionado a verde
SET_GREEN_COLOR
    SET_DRAWING_COLOR #$02
    RTS

* Subrutina para establecer el color seleccionado a rojo
SET_RED_COLOR
    SET_DRAWING_COLOR #$01
    RTS


********************************  SUBRUTINAS PARA COMPROBAR QUE NO SE DIBUJA EN DIAGONAL *****************************************


* Subrutina para evitar que se puedan dibujar celdas de manera diagonal
* Para ello primero calculamos la distancia en el eje X e Y entre la posicion de
* la ultima celda dibujada y la posicion X,Y del cursor, dibujando la nueva celda
* siempre y cuando la suma de las dos distancias no supere 1.
CHECK_DIAGONAL
    JSR CALCULATE_DIST_X       ; Calculamos la distancia X entre la ultima celda dibujada y la posicion X del cursor
    JSR CALCULATE_DIST_Y       ; Calculamos la distancia Y entre la ultima celda dibujada y la posicion X del cursor

    * Sumamos las dos distancias en la variable TOTAL_DIST
    MOVE.W X_DIST,D0
    ADD.W Y_DIST,D0
    MOVE.W D0,TOTAL_DIST

    CMP #$01,TOTAL_DIST ; Si la distancia total es menor que 1 significa que no hemos hecho un salto en diagonal
    BLS JUMP_BACK

    * En caso contrario eliminamos el camino previamente realizado y dejamos de actualizar el tablero
    DELETE_COLOR DRAWING_COLOR
    MOVE.B #$00,UPDATE

    RTS

* Subrutina para calcular la distancia X entre la ultima celda dibujada y la
* posicion X del cursor
CALCULATE_DIST_X
    MOVE.W CURSOR_COLUMN,D0
    MOVE.W LAST_DRAWED_CELL_COLUMN,D1

    * Comprobamos que numero es mayor para saber si restar D0-D1 o D1-D0
    CMP.W D1,D0
    BHI SUB_1

    SUB D0,D1        ; Resta D1-D0

    MOVE.W D1,X_DIST ; Movemos la distancia en el eje X a la variable X_DIST
    RTS

* Subrutina para restar D0-D1
SUB_1
    SUB D1,D0
    MOVE.W D0,X_DIST
    RTS

* Subrutina para calcular la distancia Y entre la ultima celda dibujada y la
* posicion Y del cursor
CALCULATE_DIST_Y
    MOVE.W CURSOR_ROW,D0
    MOVE.W LAST_DRAWED_CELL_ROW,D1

    * Comprobamos que numero es mayor para saber si restar D0-D1 o D1-D0
    CMP.W D1,D0
    BHI SUB_2

    SUB D0,D1        ; Resta D1-D0

    MOVE.W D1,Y_DIST ; Movemos la distancia en el eje X a la variable X_DIST
    RTS

* Subrutina para restar D0-D1
SUB_2
    SUB D1,D0
    MOVE.W D0,Y_DIST
    RTS


******************************** VERIFICACION DE QUE EL NIVEL SE HA COMPLETADO  *****************************************


* Subrutina encargada de comprobar si el nivel a sido superado
CHECK_VICTORY
    * Comparamos el numero de conexiones realizadas com el numero de posibles conexiones del nivel
    MOVE.B TOTAL_CONNECTIONS,D0
    CMP.B COMPLETED_CONNECTIONS,D0
    BEQ VICTORY_SCREEN
    RTS

* Subrutina encargada de mostrar la pantalla de victoria al completarse un nivel
VICTORY_SCREEN
    * Limpiamos la pantalla (ver TRAP #11)
    MOVE.L #11,D0
    MOVE.W #$FF00,D1
    TRAP #15

    * Establecemos la fuente y el tamaño del texto (ver TRAP #21)
    MOVE.L #21,D0
    MOVE.L #$0000FF00,D1
    MOVE.L #$06360001,D2
    TRAP #15

    SET_FILL_COLOR #BLACK     ; Color de fondo del texto

    * Mostramos un mensaje de victoria en pantalla (ver TRAP #95)
    MOVE.L #95,D0
    MOVE.L #VICTORY_MESSAGE,A1
    MOVE.L #125,D1
    MOVE.L #200,D2
    TRAP #15

    JSR SHOW_TIME             ; Mostramos el tiempo empleado en completar el nivel

    PLAY_SOUND #VICTORY_SOUND ; Reproducimos el sonido de victoria
    DELAY #500                ; Esperamos durante 5 segundos

    CLR.W ROW_COUNT           ; Reseteamos la cuenta de las filas
    CLR.W COLUMN_COUNT        ; Reseteamos la cuenta de las columnas
    JSR CLEAR_BOARD           ; Limpiamos el tablero de juego iterando sobre sus filas y columnas

    JMP SELECT_LEVEL          ; Saltamos a la subrutina encargada de pedir al usuario escoger un nivel

* Subrutina para mostrar en la pantalla de victoria el tiempo empleado en completar el nivel
SHOW_TIME
    * Mostramos un mensaje del tiempo total en pantalla (ver TRAP #95)
    MOVE.L #95,D0
    MOVE.L #TIME_MESSAGE,A1
    MOVE.L #25,D1
    MOVE.L #300,D2
    TRAP #15

    * Mostramos en pantalla el cronometro primer digito del cronometro (ver TRAP #95)
    MOVE.L #95,D0
    MOVE.L #DIGIT_0,A1
    ADD.B #48,(A1)     ; Sumamos 48 para representar el numero en ascii
    MOVE.L #370,D1     ; Posicion X del digito
    MOVE.L #300,D2     ; Posicion Y del digito
    TRAP #15
    SUB.B #48,(A1)                   ; Restamos 48 para dejar el valor igual que estaba antes de ser representado
    
    * Mostramos en pantalla el segundo digito del cronometro (ver TRAP #95)
    MOVE.L #95,D0
    MOVE.L #DIGIT_1,A1
    ADD.B #48,(A1)     ; Sumamos 48 para representar el numero en ascii
    MOVE.L #420,D1     ; Posicion X del digito
    MOVE.L #300,D2     ; Posicion Y del digito
    TRAP #15
    SUB.B #48,(A1)     ; Restamos 48 para dejar el valor igual que estaba antes de ser representado
    
    * Mostramos en pantalla la separacion entre minutos y segundos del cronometro (ver TRAP #95)
    MOVE.L #95,D0
    MOVE.L #COLON,A1
    MOVE.L #470,D1     ; Posicion X del texto
    MOVE.L #300,D2     ; Posicion Y del texto
    TRAP #15
   
    * Mostramos en pantalla el tercer digito del cronometro (ver TRAP #95)
    MOVE.L #95,D0
    MOVE.L #DIGIT_2,A1
    ADD.B #48,(A1)     ; Sumamos 48 para representar el numero en ascii
    MOVE.L #520,D1     ; Posicion X del digito
    MOVE.L #300,D2     ; Posicion Y del digito
    TRAP #15
    SUB.B #48,(A1)     ; Restamos 48 para dejar el valor igual que estaba antes de ser representado

    * Mostramos en pantalla el cuarto digito del cronometro (ver TRAP #95)
    MOVE.L #95,D0
    MOVE.L #DIGIT_3,A1
    ADD.B #48,(A1)     ; Sumamos 48 para representar el numero en ascii
    MOVE.L #570,D1     ; Posicion X del digito
    MOVE.L #300,D2     ; Posicion Y del digito
    TRAP #15
    SUB.B #48,(A1)     ; Restamos 48 para dejar el valor igual que estaba antes de ser representado


******************************** SUBRUTINAS PARA ELIMINAR CONEXIONES EXISTENTES *****************************************


* Subrutina para eliminar una conexion existente iterando sobre las filas y las columnas del tablero viendo si
* hay alguna celda del color de la conexion que queremos eliminar. En caso contrario significa que no hay ninguna
* conexion de ese color.
* La variable ROW_COUNT lleva la cuenta de las filas ya iteradas
* la variable COLUMN_COLUMN lleva la cuenta de las columnas iteradas
DELETE_EXISTING_CONNECTION
    MOVE.W ROW_COUNT,D0
    CMP.W ROWS,D0                       ; Comprobamos si hemos iterado todas las filas
    BGE JUMP_BACK

    CLR.W COLUMN_COUNT                  ; Reseteamos la cuenta de las columnas
    JSR DELETE_EXISTING_CONNECTION_ROW  ; Iteramos sobre la fila

    ADD.W #1,ROW_COUNT                  ; Añadimos 1 a la cuenta de las filas
    JMP DELETE_EXISTING_CONNECTION      ; Seguimos iterando filas

* Subrutina para iterar sobre una fila del tablero
DELETE_EXISTING_CONNECTION_ROW
    MOVE.W COLUMN_COUNT,D0
    CMP.W COLUMNS,D0                    ; Comprobamos si hemos llegado al final de la fila
    BGE JUMP_BACK

    JSR DELETE_EXISTING_CONNECTION_CELL ; Pasamos a la subrutina encarga de determiar si existe una conexion

    ADD.W #1,COLUMN_COUNT               ; Añadimos 1 a la cuenta de las columnas
    JMP DELETE_EXISTING_CONNECTION_ROW  ; Seguimos iterando la fila

* Subrutina para determinar si hay una conexion realizada
DELETE_EXISTING_CONNECTION_CELL
    GET_CELL ROW_COUNT,COLUMN_COUNT     ; Seleccionamos la celda

    MOVE.B DRAWING_COLOR,D0
    CMP.B SELECTED_CELL,D0              ; Comprobamos si hay una conexion realizada
    BEQ DELETE_CONNECTION

    RTS

* Subrutina para eliminar una conexion realizada
DELETE_CONNECTION
    DELETE_COLOR DRAWING_COLOR          ; Eliminamos la conexion previamente realizada
    SUB.B #1,COMPLETED_CONNECTIONS      ; Restamos 1 a la cuenta de conexiones realizadas

    MOVE.W ROWS,ROW_COUNT               ; Paramos de iterar filas
    MOVE.W COLUMNS,COLUMN_COUNT         ; Paramos de iterar columnas

    RTS


******************************** SUBRUTINAS PARA ELIMINAR UN COLOR *****************************************


* Subrutina para eliminar un color del tablero iterando sobre las filas y las columnas del tablero
* La variable ROW_COUNT lleva la cuenta de las filas ya iteradas
* la variable COLUMN_COLUMN lleva la cuenta de las columnas iteradas
DELETE_BOARD_COLOR
    MOVE.W ROW_COUNT,D0
    CMP.W ROWS,D0          ; Comprobamos si hemos iterado todas las filas
    BGE JUMP_BACK

    CLR.W COLUMN_COUNT     ; Reseteamos la cuenta de las columnas
    JSR DELETE_COLOR_ROW   ; Iteramos sobre la fila

    ADD.W #1,ROW_COUNT     ; Añadimos 1 a la cuenta de las filas
    JMP DELETE_BOARD_COLOR ; Seguimos iterando filas

* Subrutina para iterar sobre una fila del tablero
DELETE_COLOR_ROW
    MOVE.W COLUMN_COUNT,D0
    CMP.W COLUMNS,D0       ; Comprobamos si hemos llegado al final de la fila
    BGE JUMP_BACK

    JSR DELETE_COLOR_CELL  ; Pasamos a la subrutina encarga de determiar si ha de borrarse la celda

    ADD.W #1,COLUMN_COUNT  ; A?adimos 1 a la cuenta de las columnas
    JMP DELETE_COLOR_ROW   ; Seguimos iterando la fila

* Subrutina para eliminar una celda de un determinado color dado por la variable COLOR_TO_DELETE
DELETE_COLOR_CELL
    GET_CELL ROW_COUNT,COLUMN_COUNT      ; Seleccionamos la celda

    MOVE.B SELECTED_CELL,D0
    CMP.B COLOR_TO_DELETE,D0             ; Comprobamos si el tipo de celda debe borrarse
    BNE JUMP_BACK                        ; En caso de que no, volvemos atras

    SET_CELL ROW_COUNT,COLUMN_COUNT,#$00 ; Borramos la celda
    RTS


******************************** SUBRUTINAS PARA LIMPIAR EL TABLERO *****************************************


* Subrutina para limpiar el tablero de juego iterando sobre sus filas y columnas
* La variable ROW_COUNT lleva la cuenta de las filas ya iteradas
* la variable COLUMN_COLUMN lleva la cuenta de las columnas iteradas
CLEAR_BOARD
    MOVE.W ROW_COUNT,D0
    CMP.W ROWS,D0       ; Comprobamos si hemos iterado todas las filas
    BGE JUMP_BACK

    CLR.W COLUMN_COUNT  ; Reseteamos la cuenta de las columnas
    JSR CLEAR_BOARD_ROW ; Iteramos sobre la fila

    ADD.W #1,ROW_COUNT  ; A?adimos 1 a la cuenta de las filas
    JMP CLEAR_BOARD     ; Seguimos iterando filas

* Subrutina para iterar sobre una fila del tablero
CLEAR_BOARD_ROW
    MOVE.W COLUMN_COUNT,D0
    CMP.W COLUMNS,D0       ; Comprobamos si hemos llegado al final de la fila
    BGE JUMP_BACK

    JSR CLEAR_BOARD_CELL   ; Pasamos a la subrutina encarga de determiar si ha de borrarse la celda

    ADD.W #1,COLUMN_COUNT  ; Añadimos 1 a la cuenta de las columnas
    JMP CLEAR_BOARD_ROW    ; Seguimos iterando la fila

* Subrutina para eliminar todas las celdas de color del tablero
CLEAR_BOARD_CELL
    GET_CELL ROW_COUNT,COLUMN_COUNT      ; Seleccionamos la celda

    CMP.B #$80,SELECTED_CELL             ; Comprobamos si el tipo de celda debe borrarse
    BHI JUMP_BACK                        ; En caso de que no, volvemos atras

    SET_CELL ROW_COUNT,COLUMN_COUNT,#$00 ; Borramos la celda
    RTS

* Subrutina para volver a la subrutina anterior.
* A diferencia de RTS podemos utilizar esta subrutina para volver despues de ejecutar una instruccion
* del tipo BCC (BHI RTS -> no funciona | BHI JUMP_BACK -> vuelve a la subrutina de la cual fue llamada)
JUMP_BACK
    RTS

    SIMHALT


************************************** EXCEPCIONES **********************************************


    ORG $5000
* Exception que suma 1 al valor de los segundos del cronometro cada segundo
CRONOMETER
    ADD.B #1,SECONDS ; Sumamos 1 a la cuenta de los segundos
    RTE


************************************** VARIABLES **********************************************


SECONDS                  DS.B 1 ; Cuenta de los segundos del cronometro
                         DC.B 0
MINUTES                  DS.B 1 ; Cuenta de los minutos del cronometro
                         DC.B 0
                         
* Digitos del cronometro (de izquierda a derecha)
DIGIT_0                  DS.B 1 ; Digito 0 del cronometro
                         DC.B 0

DIGIT_1                  DS.B 1 ; Digito 1 del cronometro
                         DC.B 0                         

DIGIT_2                  DS.B 1 ; Digito 2 del cronometro
                         DC.B 0                       

DIGIT_3                  DS.B 1 ; Digito 3 del cronometro
                         DC.B 0
                         
                         
SELECT_LEVEL_MESSAGE     DC.L 'SELECCIONA UN NIVEL ( 1 | 2 | 3 | 4 ): ',0
VICTORY_MESSAGE          DC.L 'HAS GANADO',0
TIME_MESSAGE             DC.L 'TIEMPO=> ',0
CONNECTIONS_TEXT         DC.L 'CONEXIONES: ',0
LEVEL_TEXT               DC.L 'NIVEL: ',0
COLON                    DC.L ':',0 

VICTORY_SOUND            DC.L 'victory.wav',0
NEW_CONNECTION_SOUND     DC.L 'new_connection.wav',0
BREAK_CONNECTION_SOUND   DC.L 'break_connection.wav',0

TOTAL_CONNECTIONS        DS.B 1 ; Conexiones totales posibles para un nivel
COMPLETED_CONNECTIONS    DS.B 1 ; Numero de conexiones realizadas por el jugador
                         DC.B 0

LEVEL                    DS.B 1 ; Nivel seleccionado
                         DC.B 0

UPDATE                   DS.B 1 ; Variable que actua como flag para determinar si se deberia de actualizar el estado del tablero

ROWS                     DS.W 1 ; Numero de filas del tablero
COLUMNS                  DS.W 1 ; Numero de columnas del tablero

CELL_WIDTH               DS.W 1 ; Anchura de una celda en pixeles
CELL_HEIGHT              DS.W 1 ; Altura de una celda en pixeles

X_DIST                   DS.W 1 ; Distancia X entre la ultima celda dibujada y la posicion X del cursor
Y_DIST                   DS.W 1 ; Distancia Y entre la ultima celda dibujada y la posicion Y del cursor
TOTAL_DIST               DS.W 1 ; Distancia X,Y total entre la ultima celda dibujada y la posicion X,Y del cursor

DRAWING_COLOR            DS.B 1 ; Color de dibujado seleccionado
COLOR_TO_DELETE          DS.B 1 ; Variable que guarda el color a ser borrado cuando se llame a la subrutina DELETE_COLOR

ROW_COUNT                DS.W 1 ; Indice para iterar sobre las filas del tablero
COLUMN_COUNT             DS.W 1 ; Indice para iterar sobre las columnas del tablero

SELECTED_CELL            DS.B 1 ; Tipo de celda
CELL_UNDER_CURSOR        DS.B 1 ; Tipo de celda debajo del cursor

CELL_X                   DS.W 1 ; Coordenada X de la celda
CELL_Y                   DS.W 1 ; Coordenada Y de la celda

CURSOR_ROW               DS.W 1 ; Fila donde esta situado el cursor
CURSOR_COLUMN            DS.W 1 ; Columna donde esta situado el cursor

LAST_DRAWED_CELL_ROW     DS.W 1 ; Posicion Y de la ultima celda rectangular dibujada
LAST_DRAWED_CELL_COLUMN  DS.W 1 ; Posicion X de la ultima celda rectangular dibujada

LAST_ROUNDED_CELL_ROW    DS.W 1 ; Posicion X de la ultima celda redonda dibujada
LAST_ROUNDED_CELL_COLUMN DS.W 1 ; Posicion Y de la ultima celda redonda dibujada

TABLERO_LVL_1
                         DC.B $00,$00,$00,$84,$00
                         DC.B $82,$81,$00,$83,$00
                         DC.B $00,$00,$00,$00,$00
                         DC.B $00,$00,$00,$00,$00
                         DC.B $81,$82,$83,$00,$84
TABLERO_LVL_2
                         DC.B $84,$00,$00,$00,$85
                         DC.B $00,$00,$83,$00,$00
                         DC.B $84,$00,$00,$85,$00
                         DC.B $82,$00,$00,$82,$83
                         DC.B $81,$00,$00,$00,$81

TABLERO_LVL_3
                         DC.B $83,$00,$00,$89,$87,$00,$00,$86
                         DC.B $00,$00,$00,$00,$00,$88,$00,$00
                         DC.B $00,$00,$88,$00,$00,$00,$00,$00
                         DC.B $00,$89,$00,$00,$00,$00,$85,$00
                         DC.B $00,$00,$00,$85,$00,$87,$86,$00
                         DC.B $81,$00,$00,$00,$00,$00,$82,$00
                         DC.B $00,$00,$00,$83,$84,$00,$84,$00
                         DC.B $00,$81,$82,$00,$00,$00,$00,$00

TABLERO_LVL_4
                         DC.B $00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                         DC.B $00,$00,$82,$86,$8A,$00,$00,$00,$8A,$00
                         DC.B $00,$00,$87,$00,$00,$00,$00,$00,$00,$00
                         DC.B $00,$00,$00,$83,$00,$00,$88,$89,$00,$00
                         DC.B $00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                         DC.B $00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                         DC.B $00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                         DC.B $00,$00,$00,$00,$00,$85,$88,$00,$00,$81
                         DC.B $00,$00,$87,$00,$86,$84,$89,$00,$00,$00
                         DC.B $81,$00,$82,$00,$83,$00,$00,$00,$84,$85

    END    START


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
