function [p_order] = session_profiles(session_type)
%SESSION_PROFILES Gets the pure behavior variables associated with the
%session type

arguments
    session_type (1,1) string {mustBeMember(session_type,["Cocaine SA","Food SA","Food ext"])}
end

switch(session_type)
    case("Cocaine SA")
        p_order = [13,12,11,10,9,8,5,4,3,2];
    case("Food SA")
        p_order = [13,12,11,10,9,8,7,6,5,4,3,1];
    case("Food ext")
        p_order = [13,12,11,10,9,8,5,4,3,1];
end

end