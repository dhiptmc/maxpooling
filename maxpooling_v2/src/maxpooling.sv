parameter inputsize = 128;
parameter countersize = 7;
parameter outputsize = inputsize/2;

module maxpooling(
    input   clk,
    input   rst,
    input   ready,      // input ready
    output logic busy,  // system busy signal
    output logic ren,   // read enable
    output logic wen,   // write enable
    //input        [15:0] cdata_rd [7:0], //version 2; read 16byte in 1 cycle
    input        [15:0] cdata_rd7,
    input        [15:0] cdata_rd6,
    input        [15:0] cdata_rd5,
    input        [15:0] cdata_rd4,
    input        [15:0] cdata_rd3,
    input        [15:0] cdata_rd2,
    input        [15:0] cdata_rd1,
    input        [15:0] cdata_rd0,
    output logic [2*countersize-1:0] caddr_rd,       //max 128*128
    output logic [7:0]  mdata_wr,
    output logic [2*(countersize-1)-1:0] maddr_wr        //max 64*64
);

logic [2:0] cur_state, nxt_state;
parameter   IDLE          = 3'd0,
            READ          = 3'd1,
            UPLF          = 3'd2,
            LWLF          = 3'd3,
            UPRG          = 3'd4,
            LWRG          = 3'd5,
            FINISH        = 3'd6;


logic [2*countersize-1:0]   cur_paddr; //prior addr
//logic [2*(countersize-1):0] cur_laddr; //latter addr
logic [2*countersize-1:0] jump;
assign jump = cur_paddr + 4;


logic [7:0] rowbuffer [inputsize-1:0];
logic [7:0] corner;
logic [7:0] colbuffer [3:0];
logic [countersize-1:0] counter;

logic [2*(countersize-1):0] iindex1, iindex2, iindex3, iindex4;

logic [7:0] UL,UP,UR,LF,CUR,RG,LL,DW,LR;
logic [7:0] max1, max2, max3, max4, max5, max6, max7;

assign max1 = (UL>UP)  ? UL : UP;
assign max2 = (LF>CUR) ? LF : CUR;
assign max3 = (LL>DW)  ? LL : DW; 
assign max4 = (max1>UR) ? max1 : UR;
assign max5 = (max2>RG) ? max2 : RG;
assign max6 = (max3>LR) ? max3 : LR;
assign max7 = (max4>max5) ? max4 : max5;
assign mdata_wr = (max7>max6) ? max7 : max6;

always_ff @(posedge clk or posedge rst)
begin
    if(rst)
        cur_state <= IDLE;
    else
        cur_state <= nxt_state;
end

always_comb 
begin
    case(cur_state)
        IDLE:
        begin
            if(ready)
                nxt_state = READ;
            else
                nxt_state = IDLE; 
        end

        READ:
        begin
            nxt_state = UPLF;
        end

        UPLF:
        begin
            nxt_state = LWLF;
        end

        LWLF:
        begin
            nxt_state = UPRG;
        end

        UPRG:
        begin
            nxt_state = LWRG;
        end

        LWRG:
        begin
            nxt_state = FINISH;
        end

        FINISH:
        begin
            if(ready || busy)
                nxt_state = READ;
            else
                nxt_state = IDLE;
        end


        default:
            nxt_state = IDLE;    

    endcase
end

always_ff @(posedge clk or posedge rst)
begin
    if(rst)
    begin
        busy <= 1'b0;
        wen <= 1'b0;
        ren <= 1'b0;
        caddr_rd <= 14'b0;
        maddr_wr <= 12'b0;
        cur_paddr <= 14'b0;
        counter <= 0;
        iindex1 <= 0;
        iindex2 <= 0;
        iindex3 <= 0;
        iindex4 <= 0;
    end

    else
    begin
        case(cur_state)
            IDLE:
            begin
                busy <= 1'b0;
                wen <= 1'b0;
                ren <= 1'b1;
                caddr_rd <= 14'b0;
                maddr_wr <= 12'b0;
                cur_paddr <= 14'b0;
                counter <= 0;
                iindex1 <= 0;
                iindex2 <= outputsize;
                iindex3 <= 1;
                iindex4 <= outputsize + 1;
            end

            READ:
            begin
                busy <= 1'b1;
                caddr_rd <= cur_paddr;
                if($unsigned(~(cur_paddr[countersize-1:0])) == (inputsize - 1) )
                    counter <= 0;
                else
                    counter <= counter + 4;

            end

            UPLF:
            begin
                wen <= 1'b1;
                CUR<= cdata_rd0[15:8];
                RG <= cdata_rd0[7:0];
                DW <= cdata_rd1[15:8];
                LR <= cdata_rd1[7:0];          
                
                if( (counter == 0) && (cur_paddr < inputsize) )
                begin
                    UL <= 0;
                    UP <= 0;
                    UR <= 0;
                    LF <= 0;
                    LL <= 0;
                end
                else if (cur_paddr < inputsize)
                begin
                    UL <= 0;
                    UP <= 0;
                    UR <= 0;
                    LF <= colbuffer[0];
                    LL <= colbuffer[1];
                end
                else if (counter == 0)
                begin
                    UL <= 0;
                    UP <= rowbuffer[0];
                    UR <= rowbuffer[1];
                    LF <= 0;
                    LL <= 0;
                end
                else
                begin
                    UL <= corner;
                    UP <= rowbuffer[iindex1%outputsize+iindex1%outputsize];
                    UR <= rowbuffer[iindex1%outputsize+iindex1%outputsize+1];
                    LF <= colbuffer[0];
                    LL <= colbuffer[1];                  
                end

                maddr_wr <= iindex1;
            end

            LWLF:
            begin
                wen <= 1'b1;
                UP <= cdata_rd1[15:8];
                UR <= cdata_rd1[7:0];
                CUR<= cdata_rd2[15:8];
                RG <= cdata_rd2[7:0];
                DW <= cdata_rd3[15:8];
                LR <= cdata_rd3[7:0];          
                
                if(counter == 0)
                begin
                    UL <= 0;
                    LF <= 0;
                    LL <= 0;
                end
                else
                begin
                    UL <= colbuffer[1];
                    LF <= colbuffer[2];
                    LL <= colbuffer[3];                  
                end

                maddr_wr <= iindex2;
            end

            UPRG:
            begin
                wen <= 1'b1;
                LF <= cdata_rd0[7:0]; 
                CUR<= cdata_rd4[15:8];
                RG <= cdata_rd4[7:0];
                LL <= cdata_rd1[7:0];
                DW <= cdata_rd5[15:8];
                LR <= cdata_rd5[7:0];          
                
                if(cur_paddr < inputsize)
                begin
                    UL <= 0;
                    UP <= 0;
                    UR <= 0;
                end
                else
                begin
                    UL <= rowbuffer[iindex3%outputsize+iindex3%outputsize-1];
                    UP <= rowbuffer[iindex3%outputsize+iindex3%outputsize];
                    UR <= rowbuffer[iindex3%outputsize+iindex3%outputsize+1];
                end

                maddr_wr <= iindex3;
            end

            LWRG:
            begin
                wen <= 1'b1;
                UL <= cdata_rd1[7:0];
                UP <= cdata_rd5[15:8];
                UR <= cdata_rd5[7:0];
                LF <= cdata_rd2[7:0];
                CUR<= cdata_rd6[15:8];
                RG <= cdata_rd6[7:0];               
                LL <= cdata_rd3[7:0];
                DW <= cdata_rd7[15:8];
                LR <= cdata_rd7[7:0];

                maddr_wr <= iindex4;
            end

            FINISH:
            begin
                wen <= 1'b0;
                colbuffer[0]            <= cdata_rd4[7:0];
                colbuffer[1]            <= cdata_rd5[7:0];
                colbuffer[2]            <= cdata_rd6[7:0];
                colbuffer[3]            <= cdata_rd7[7:0];
                rowbuffer[counter]      <= cdata_rd3[15:8];
                rowbuffer[counter+1]    <= cdata_rd3[7:0];
                rowbuffer[counter+2]    <= cdata_rd7[15:8];
                rowbuffer[counter+3]    <= cdata_rd7[7:0];
                corner                  <= rowbuffer[counter+3]; 
                
                if(jump[countersize-1:0] == 0)
                begin
                    iindex1 <= iindex1 + 2 + outputsize;
                    iindex2 <= iindex2 + 2 + outputsize;
                    iindex3 <= iindex3 + 2 + outputsize;
                    iindex4 <= iindex4 + 2 + outputsize;
                    cur_paddr <= cur_paddr + 3*inputsize + 4;
                end
                else
                begin
                    cur_paddr <= jump;
                    iindex1 <= iindex1 + 2;
                    iindex2 <= iindex2 + 2;
                    iindex3 <= iindex3 + 2;
                    iindex4 <= iindex4 + 2;
                end
                
                if(iindex4 >= outputsize*outputsize-1)
                    busy <= 1'b0;                  
            end
        endcase
    end
end

endmodule