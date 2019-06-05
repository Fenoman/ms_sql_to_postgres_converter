CREATE OR REPLACE FUNCTION gethostbyaddr(INET)
  RETURNS TEXT
AS
-- =============================================
-- Author:  e-pavlichenko
-- Create date: 17.05.2018
-- Alter date:  17.05.2018
-- Description: хост
-- =============================================
$$
use strict;
use Socket;
my $inet = $_[0];
my $iaddr=inet_aton($inet);
my $name = gethostbyaddr($iaddr,AF_INET);
return $name;
$$
LANGUAGE plperlu STRICT STABLE;