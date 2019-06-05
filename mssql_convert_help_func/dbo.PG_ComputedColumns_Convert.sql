IF OBJECT_ID('dbo.PG_ComputedColumns_Convert') IS NOT NULL
	DROP FUNCTION dbo.PG_ComputedColumns_Convert
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		e-pavlichenko
-- CREATE date: 13.06.2018
-- Alter date:	13.06.2018
-- Description:	Конвертация выражений в вычисляемых полях
-- =============================================
CREATE FUNCTION dbo.PG_ComputedColumns_Convert
(
	@string VARCHAR(5000),
	@B_Trigger_Update BIT
)
RETURNS VARCHAR(5000)
AS
BEGIN 
	SET @string = 
		CASE @string
			WHEN 'expression' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'expression in pl/pg SQL'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'expression for update trigger'
					 END
			ELSE @string
		END
	
	/* -- Examples
	SET @string = 
		CASE @string
			WHEN '(isnull([D_Date_End_TS],[D_Date_End]))' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'coalesce(NEW.D_Date_End_TS, NEW.D_Date_End)'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.D_Date_End_TS IS DISTINCT FROM NEW.D_Date_End_TS OR OLD.D_Date_End IS DISTINCT FROM NEW.D_Date_End'
					 END
			
			WHEN '(power((2),[N_Bit_Number]))' 
				THEN
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'power(2, NEW.N_Bit_Number)'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.N_Bit_Number IS DISTINCT FROM NEW.N_Bit_Number'
					END
			
			WHEN '([N_Year]*(100)+[N_Month])' 
				THEN
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'NEW.N_Year*100 + NEW.N_Month'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.N_Year IS DISTINCT FROM NEW.N_Year OR OLD.N_Month IS DISTINCT FROM NEW.N_Month'
					END
			
			WHEN '(([N_Month]+(2))/(3))'
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN '(NEW.N_Month + 2) / 3'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.N_Month IS DISTINCT FROM NEW.N_Month'
					END
			
			WHEN '(isnull(nullif(([N_Month]+(2))/(3)-(1),(0)),(4)))' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'coalesce(nullif((NEW.N_Month+2)/3-1,0),4)'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.N_Month IS DISTINCT FROM NEW.N_Month'
					END
			
			WHEN '(datediff(hour,[D_Date0],[D_Date1])+(24))' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'datediff(''hour'', NEW.D_Date0, NEW.D_Date1)+24'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.D_Date0 IS DISTINCT FROM NEW.D_Date0 OR OLD.D_Date1 IS DISTINCT FROM NEW.D_Date1'
					END
			
			WHEN '(dateadd(month,(1),[D_Date0]))' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'NEW.D_Date0 + interval ''1 month'''
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.D_Date0 IS DISTINCT FROM NEW.D_Date0'
					END
			
			WHEN '([ID])' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'NEW.ID'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.ID IS DISTINCT FROM NEW.ID'
					END
			
			WHEN '(case when datepart(minute,isnull([D_Date_End_TS],[D_Date_End]))<(30) then dateadd(minute, -datepart(minute,isnull([D_Date_End_TS],[D_Date_End])),isnull([D_Date_End_TS],[D_Date_End])) else dateadd(minute,(60)-datepart(minute,isnull([D_Date_End_TS],[D_Date_End])),isnull([D_Date_End_TS],[D_Date_End])) end)' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'CASE WHEN date_part(''minute'',coalesce(NEW.D_Date_End_TS,NEW.D_Date_End))<30 THEN coalesce(NEW.D_Date_End_TS,NEW.D_Date_End) - date_part(''minute'',coalesce(NEW.D_Date_End_TS,NEW.D_Date_End)) * interval ''1 minute'' ELSE coalesce(NEW.D_Date_End_TS,NEW.D_Date_End) + (60 - date_part(''minute'',coalesce(NEW.D_Date_End_TS,NEW.D_Date_End))) * interval ''1 minute'' END'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.D_Date_End_TS IS DISTINCT FROM NEW.D_Date_End_TS OR OLD.D_Date_End IS DISTINCT FROM NEW.D_Date_End'
					END

			WHEN '(CONVERT([tinyint],case when [D_Date_End] IS NOT NULL then (1) else (0) end,(0)))' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'CASE WHEN NEW.D_Date_End IS NOT NULL THEN 1 ELSE 0 END::smallint'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.D_Date_End IS DISTINCT FROM NEW.D_Date_End'
					END
			
			WHEN '(dateadd(minute, -datepart(minute,[D_Date]),[D_Date]))' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'NEW.D_Date - date_part(''minute'',NEW.D_Date) * interval ''1 minute'''
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.D_Date IS DISTINCT FROM NEW.D_Date'
					END

			WHEN '(case when isnumeric([C_Value])=(1) AND len(replace([C_Value],''-'',''''))<(20) AND patindex(''%.%'',replace([C_Value],'','',''.''))=(0) then CONVERT([bigint],[C_Value])  end)' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'CASE WHEN isnumeric(NEW.C_Value)=TRUE AND length(replace(NEW.C_Value,''-'','''')) < 20 AND replace(NEW.C_Value,'','',''.'') NOT LIKE ''%.%'' THEN NEW.C_Value::bigint END'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.C_Value IS DISTINCT FROM NEW.C_Value'
					END

			WHEN '(case when [C_Value] like replace(''00000000-0000-0000-0000-000000000000'',''0'',''[0-9a-fA-F]'') then CONVERT([uniqueidentifier],[C_Value])  end)' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'CASE WHEN isuuid(NEW.C_Value) = true THEN NEW.C_Value::UUID END'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.C_Value IS DISTINCT FROM NEW.C_Value'
					END

			WHEN '(datepart(year,[D_Post_Date]))' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'date_part(''year'', NEW.D_Post_Date)'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.D_Post_Date IS DISTINCT FROM NEW.D_Post_Date'
					END
			
			WHEN '(datepart(month,[D_Post_Date]))' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'date_part(''month'', NEW.D_Post_Date)'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.D_Post_Date IS DISTINCT FROM NEW.D_Post_Date'
					END
			
			WHEN '(((isnull([N_Amount],(0))-isnull([N_Amount_Duty],(0)))-isnull([N_Amount_Peni],(0)))-isnull([N_Amount_Debt],(0)))' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN '((coalesce(NEW.N_Amount, 0) - coalesce(NEW.N_Amount_Duty, 0)) - coalesce(NEW.N_Amount_Peni, 0)) - coalesce(NEW.N_Amount_Debt, 0)'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.N_Amount IS DISTINCT FROM NEW.N_Amount OR OLD.N_Amount_Duty IS DISTINCT FROM NEW.N_Amount_Duty OR OLD.N_Amount_Peni IS DISTINCT FROM NEW.N_Amount_Peni OR OLD.N_Amount_Debt IS DISTINCT FROM NEW.N_Amount_Debt'
					END

			WHEN '([B_House_Meter]|[B_House_Needs])'
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'NEW.B_House_Meter OR NEW.B_House_Needs'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.B_House_Meter IS DISTINCT FROM NEW.B_House_Meter OR OLD.B_House_Needs IS DISTINCT FROM NEW.B_House_Needs'
					END

			WHEN '([dbo].[CF_FIO_Short]([C_Name1],[C_Name2],[C_Name3]))' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'dbo.CF_FIO_Short(NEW.C_Name1, NEW.C_Name2, NEW.C_Name3)'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.C_Name1 IS DISTINCT FROM NEW.C_Name1 OR OLD.C_Name2 IS DISTINCT FROM NEW.C_Name2 OR OLD.C_Name3 IS DISTINCT FROM NEW.C_Name3'
					END

			WHEN '([N_DT_Year]*(100)+[N_DT_Month])' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'NEW.N_DT_Year*100 + NEW.N_DT_Month'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.N_DT_Year IS DISTINCT FROM NEW.N_DT_Year'
					END

			WHEN '([N_PE_Quan_Meter]+[N_PE_Quan_Norm])' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'NEW.N_PE_Quan_Meter + NEW.N_PE_Quan_Norm'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.N_PE_Quan_Meter IS DISTINCT FROM NEW.N_PE_Quan_Meter OR OLD.N_PE_Quan_Norm IS DISTINCT FROM NEW.N_PE_Quan_Norm'
					END

			WHEN '([N_PE_Quan_Meter0]+[N_PE_Quan_Norm0])' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'NEW.N_PE_Quan_Meter0 + NEW.N_PE_Quan_Norm0'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.N_PE_Quan_Meter0 IS DISTINCT FROM NEW.N_PE_Quan_Meter0 OR OLD.N_PE_Quan_Norm0 IS DISTINCT FROM NEW.N_PE_Quan_Norm0'
					END

			WHEN '([N_Period]%(100))' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'NEW.N_Period%100'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.N_Period IS DISTINCT FROM NEW.N_Period'
					END
			
			WHEN '([N_Period]/(100))' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'NEW.N_Period/100'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.N_Period IS DISTINCT FROM NEW.N_Period'
					END

			WHEN '([N_Quantity]+[N_Quantity_Corr])' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'NEW.N_Quantity + NEW.N_Quantity_Corr'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.N_Quantity IS DISTINCT FROM NEW.N_Quantity OR OLD.N_Quantity_Corr IS DISTINCT FROM NEW.N_Quantity_Corr'
					END

			WHEN '(case when datepart(minute,[D_Date])<(30) then dateadd(minute, -datepart(minute,[D_Date]),[D_Date]) else dateadd(minute,(60)-datepart(minute,[D_Date]),[D_Date]) end)' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'CASE WHEN date_part(''minute'', NEW.D_Date) < 30 THEN NEW.D_Date - date_part(''minute'', NEW.D_Date) * interval ''1 minute'' ELSE NEW.D_Date + (60 - date_part(''minute'',NEW.D_Date)) * interval ''1 minute'' END'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.D_Date IS DISTINCT FROM NEW.D_Date'
					END

			WHEN '(case when datepart(minute,[D_Date_Prev])<(30) then dateadd(minute, -datepart(minute,[D_Date_Prev]),[D_Date_Prev]) else dateadd(minute,(60)-datepart(minute,[D_Date_Prev]),[D_Date_Prev]) end)' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'CASE WHEN date_part(''minute'', NEW.D_Date_Prev) < 30 THEN NEW.D_Date_Prev - date_part(''minute'', NEW.D_Date_Prev) * interval ''1 minute'' ELSE NEW.D_Date_Prev + (60 - date_part(''minute'', NEW.D_Date_Prev)) * interval ''1 minute'' END'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.D_Date_Prev IS DISTINCT FROM NEW.D_Date_Prev'
					END

			WHEN '(case when datepart(minute,isnull([D_Date_End_TS],[D_Date_End]))<(30) then dateadd(minute, -datepart(minute,isnull([D_Date_End_TS],[D_Date_End])),isnull([D_Date_End_TS],[D_Date_End])) else dateadd(minute,(60)-datepart(minute,isnull([D_Date_End_TS],[D_Date_End])),isnull([D_Date_End_TS],[D_Date_End])) end)' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0 
							----------------------------------------------------------------
							THEN 'CASE WHEN date_part(''minute'', coalesce(NEW.D_Date_End_TS, NEW.D_Date_End)) < 30 THEN coalesce(NEW.D_Date_End_TS, NEW.D_Date_End) - date_part(''minute'', coalesce(NEW.D_Date_End_TS, NEW.D_Date_End)) * interval ''1 minute'' ELSE coalesce(NEW.D_Date_End_TS, NEW.D_Date_End) + (60 - date_part(''minute'', coalesce(NEW.D_Date_End_TS, NEW.D_Date_End))) * interval ''1 minute'' END'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.D_Date_End_TS IS DISTINCT FROM NEW.D_Date_End_TS OR OLD.D_Date_End IS DISTINCT FROM NEW.D_Date_End'
					END

			WHEN '(case when datepart(minute,isnull([D_Date_TS],[D_Date]))<(30) then dateadd(minute, -datepart(minute,isnull([D_Date_TS],[D_Date])),isnull([D_Date_TS],[D_Date])) else dateadd(minute,(60)-datepart(minute,isnull([D_Date_TS],[D_Date])),isnull([D_Date_TS],[D_Date])) end)' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'CASE WHEN date_part(''minute'', coalesce(NEW.D_Date_TS, NEW.D_Date)) < 30 THEN coalesce(NEW.D_Date_TS, NEW.D_Date) - date_part(''minute'', coalesce(NEW.D_Date_TS, NEW.D_Date)) * interval ''1 minute'' ELSE coalesce(NEW.D_Date_TS, NEW.D_Date) + (60 - date_part(''minute'', coalesce(NEW.D_Date_TS, NEW.D_Date))) * interval ''1 minute'' END'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.D_Date_TS IS DISTINCT FROM NEW.D_Date_TS OR OLD.D_Date IS DISTINCT FROM NEW.D_Date'
					END

			WHEN '(case when substring([C_Address],charindex(char((160)),[C_Address])+(1),(2))='', '' then substring([C_Address],charindex(char((160)),[C_Address])+(3),len([C_Address])) else substring([C_Address],charindex(char((160)),[C_Address])+(1),len([C_Address])) end)' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'CASE WHEN substring(NEW.C_Address from position(chr(160) in NEW.C_Address) + 1 for 2) = '', '' THEN substring(NEW.C_Address from position(chr(160) in NEW.C_Address) + 3 for length(NEW.C_Address)) ELSE substring(NEW.C_Address from position(chr(160) in NEW.C_Address) + 1 for length(NEW.C_Address)) END'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.C_Address IS DISTINCT FROM NEW.C_Address'
					END

			WHEN '(checksum([C_Receipt_Info]))' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'checksum(NEW.C_Receipt_Info)'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.C_Receipt_Info IS DISTINCT FROM NEW.C_Receipt_Info'
					END

			WHEN '(checksum([C_Receipt_Info_Add]))' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'checksum(NEW.C_Receipt_Info_Add)'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.C_Receipt_Info_Add IS DISTINCT FROM NEW.C_Receipt_Info_Add'
					END

			WHEN '(dateadd(day,(-1),dateadd(month,(1),CONVERT([datetime],CONVERT([varchar](8),(([N_Dt_Period]/(100))*(10000)+([N_Dt_Period]%(100))*(100))+(1)),(112)))))' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN '(((NEW.N_Dt_Period/100)*10000 + (NEW.N_Dt_Period%100) * 100) + 1)::text::timestamptz + INTERVAL ''1 month'' - INTERVAL ''1 day'''
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.N_Dt_Period IS DISTINCT FROM NEW.N_Dt_Period'
					END

			WHEN '(dateadd(day,(-1),dateadd(month,(1),CONVERT([datetime],CONVERT([varchar](8),(([N_Period]/(100))*(10000)+([N_Period]%(100))*(100))+(1)),(112)))))' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN '(((NEW.N_Period/100)*10000 + (NEW.N_Period%100) * 100) + 1)::text::timestamptz + INTERVAL ''1 month'' - INTERVAL ''1 day'''
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.N_Period IS DISTINCT FROM NEW.N_Period'
					END

			WHEN '(datediff(day,[D_Date_Prev],isnull([D_Date_TS],[D_Date])))' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'datediff(''day'', NEW.D_Date_Prev, coalesce(NEW.D_Date_TS, NEW.D_Date))'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.D_Date_Prev IS DISTINCT FROM NEW.D_Date_Prev OR OLD.D_Date_TS IS DISTINCT FROM NEW.D_Date_TS OR OLD.D_Date IS DISTINCT FROM NEW.D_Date'
					END

			WHEN '(datepart(month,[D_Date]))' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'date_part(''month'', NEW.D_Date)'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.D_Date IS DISTINCT FROM NEW.D_Date'
					END

			WHEN '(datepart(month,[D_Date_Begin]))' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'date_part(''month'', NEW.D_Date_Begin)'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.D_Date_Begin IS DISTINCT FROM NEW.D_Date_Begin'
					END

			WHEN '(datepart(month,isnull([D_Date_TS],[D_Date])))' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'date_part(''month'', coalesce(NEW.D_Date_TS, NEW.D_Date))'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.D_Date_TS IS DISTINCT FROM NEW.D_Date_TS OR OLD.D_Date IS DISTINCT FROM NEW.D_Date'
					END

			WHEN '(datepart(year,[D_Date]))' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'date_part(''year'', NEW.D_Date)'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.D_Date IS DISTINCT FROM NEW.D_Date'
					END

			WHEN '(datepart(year,[D_Date])*(100)+datepart(month,[D_Date]))' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'date_part(''year'', NEW.D_Date) * 100 + date_part(''month'', NEW.D_Date)'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1 
							THEN 'OLD.D_Date IS DISTINCT FROM NEW.D_Date'
					END

			WHEN '(datepart(year,[D_Date_Begin]))' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'date_part(''year'', NEW.D_Date_Begin)'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.D_Date_Begin IS DISTINCT FROM NEW.D_Date_Begin'
					END

			WHEN '(datepart(year,[D_Date_Begin])*(100)+datepart(month,[D_Date_Begin]))' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'date_part(''year'', NEW.D_Date_Begin) * 100 + date_part(''month'', NEW.D_Date_Begin)'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.D_Date_Begin IS DISTINCT FROM NEW.D_Date_Begin'
					END

			WHEN '(datepart(year,[D_Date0])*(100)+datepart(month,[D_Date0]))' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'date_part(''year'', NEW.D_Date0) * 100 + date_part(''month'', NEW.D_Date0)'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.D_Date0 IS DISTINCT FROM NEW.D_Date0'
					END

			WHEN '(datepart(year,isnull([D_Date_TS],[D_Date])))' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'date_part(''year'', coalesce(NEW.D_Date_TS, NEW.D_Date))'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.D_Date_TS IS DISTINCT FROM NEW.D_Date_TS OR OLD.D_Date IS DISTINCT FROM NEW.D_Date'
					END

			WHEN '(floor([N_Period]/(100)))' 
				THEN 
					CASE 
						WHEN @B_Trigger_Update = 0
							----------------------------------------------------------------
							THEN 'floor(NEW.N_Period/100)'
							----------------------------------------------------------------
						WHEN @B_Trigger_Update = 1
							THEN 'OLD.N_Period IS DISTINCT FROM NEW.N_Period'
					END

			ELSE @string
		END
	*/

	RETURN @string
	
END
GO