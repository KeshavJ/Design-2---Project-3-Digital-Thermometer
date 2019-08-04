;*******************************************************************************								    	            
;    Student Name	    : Keshav Jeewanlall			            
;    Student Number	    : 213508238	                                                
;    Date		    : 05 / 09 / 2017                                    
;    Description	    : A digital thermometer using a LM35 chip 
;			      and two SSDs.
;    
;   This code processes an analogue input from a LM35 chip and displays the 
;   result on two multiplexed SSDs.       
;*******************************************************************************

    List p=16f690			
#include <p16F690.inc>		
errorlevel  -302		
    __CONFIG   _CP_OFF & _CPD_OFF & _BOR_OFF & _MCLRE_ON & _WDT_OFF & _PWRTE_ON & _INTRC_OSC_NOCLKOUT & _FCMEN_OFF & _IESO_OFF 

;************************VARIABLE DEFINITIONS & VECTORS*************************         
 UDATA
tens		  RES 1	    ;stores tens digit
units		  RES 1	    ;stores units digit 
temp	          RES 1	    
		  
EXTERN Binary_To_BCD	    ;library to convert binary to BCD
	     
RESET ORG 0x00		    ;Reset vector, PIC starts here on power up and reset
GOTO Setup
    
 ;*****************************SETUP OF PIC16F690*******************************
Setup
				;Use Bank0
    BCF STATUS,5
    BCF STATUS,6		 
     
     CLRF PORTA			;Initialise Port A
     CLRF PORTB			;Initialise Port B
     CLRF PORTC			;Initialise Port C
     
				;Load 01001101 into ADCONO to Adjust left, 
				;use external Vref, enable AN3 and enable ADC
     MOVLW 0x4D
     MOVWF ADCON0		
				;Use Bank 1
     BSF STATUS,5	
     
     CLRF TRISC			;Set PORTC as output
     BSF TRISA,4		;Set RA4 as input for the LM35
     BSF TRISA,1		;Set RA1 as input. Used to read Vref
     BCF TRISA,5		;RA5 used to control the Units SSD
     CLRF ADCON1		;Conversion cloack set at FOSC/2
     
				;Use Bank 2
    BCF STATUS,5
    BSF STATUS,6
     
     CLRF ANSEL			;Initialize all ports as digital I/O
     CLRF ANSELH
     BSF ANSEL,3		;Set RA4/AN3 to be analog input
     BSF ANSEL,1		;Set Vref to be analog input
     
				;Set back to Bank 0		
     BCF STATUS,6
          
     GOTO Get_Temperature
     
     CODE
 ;********************CODE TO GET TEMPERATURE FROM LM35***********************
     
Get_Temperature
			    ;Conversion is initiated by setting the GO/DONE 
			    ;bit ADCON0<1>
			    
    BSF ADCON0,1	    ;Start ADC conversion
    
Get_Temperature_Loop
    BTFSC ADCON0,1	    ;Checks if conversion done, if so, exit loop
    GOTO Get_Temperature_Loop	  
    MOVFW ADRESH	    ;Move conversion result to WREG
    Call Display
    GOTO Get_Temperature	    
    
;************************CODE FOR DISPLAYING ON SSDs****************************
    
Display
    CALL Convert_to_BCD	    ;subroutine to convert count to BCD
    CALL SSD_Table	    ;gets code for displaying the number (Tens)
    ADDLW 0x80		    ;setting the MSB (Bit 7) will enable the Tens SSD
    MOVWF PORTC		    ;display Tens value
    CALL Multiplexing_Delay ;delay for multiplexing SSDs
    BCF PORTC,7		    ;Disable tens SSD
    MOVFW units		    
    CALL SSD_Table	    ;gets code for displaying the number (Units)
    BSF PORTA,5		    ;Set RA5 to enable units SSD
    MOVWF PORTC		    ;displays units value
    CALL Multiplexing_Delay 
    BCF PORTA,5		    ;Disable the Units SSD
    RETURN
    
Convert_to_BCD		  ;converts count to BCD
    Call Binary_To_BCD	  ;uses library subroutine to get BCD value of number
    MOVWF tens
    ANDLW 0x0F		  ;b'00001111 , clears upper nibble of BCD number
    MOVWF units		  ;stores the value as the units
    SWAPF tens,1	  ;swaps the nibbles of the BCD number
    MOVFW tens		  
    ANDLW 0x0F		  ;b'00001111, clears the high nibble to get tens value
    MOVWF tens		  ;stores value in tens register
    RETURN

;This subroutine adds the value that is in the W register to the Program 
;Counter. PC will skip to whichever value is needed to be displayed and returns
;the value in the WREG.

    
SSD_Table
			  ;These HEX values are required because common anode SSDs
			  ;are being used
    ADDWF PCL,1
    RETLW 0x40		  ;displays number 0 on SSD
    RETLW 0x79		  ;displays number 1 on SSD    
    RETLW 0x24		  ;displays number 2 on SSD
    RETLW 0x30		  ;displays number 3 on SSD
    RETLW 0x19		  ;displays number 4 on SSD
    RETLW 0x12		  ;displays number 5 on SSD
    RETLW 0x02		  ;displays number 6 on SSD
    RETLW 0x78		  ;displays number 7 on SSD
    RETLW 0x00		  ;displays number 8 on SSD
    RETLW 0x10		  ;displays number 9 on SSD
 
Multiplexing_Delay	 ;A delay subroutine. Runs for approx. 0.125ms 
    MOVLW 0xFA		 ;Loads a value of 250 and stores it in temp
    MOVWF temp
Multiplexing_Delay_Loop
    DECFSZ temp,1	 ;When temp = 0, exit loop
    GOTO Multiplexing_Delay_Loop
    RETURN
    
    END



