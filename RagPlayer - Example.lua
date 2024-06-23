--@name RagPlayer - Example
--@author toakley682
--@shared
--@include libs/ragdoll_player_library.txt
require( "libs/ragdoll_player_library.txt" )

if SERVER then
    
    local Punch = Ability( "Punch" )
    
    Punch.Hand = false
    
    Punch:OnPress( function( Ability, Ragdoll )
        
        Ability.Hand = !Ability.Hand
        
        if Ability.Hand == true then
            
            Ragdoll.RHand:applyForceCenter( Ragdoll.Facing:getRight() * 10000 )
            
        else
            
            Ragdoll.LHand:applyForceCenter( Ragdoll.Facing:getRight() * 10000 )
            
        end
        
    end)
    
    Punch:OnRelease( function( Ability, Ragdoll )
        
        
        
    end)
    
    Punch:OnTick( function( Ability, Ragdoll )
        
        
        
    end)
    
    local Abilities = { Punch }
    
    local Rag = RagPlayer( owner(), Abilities )
    
end
