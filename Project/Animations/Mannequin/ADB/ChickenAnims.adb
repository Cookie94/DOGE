<AnimDB FragDef="Animations/Mannequin/Chicken/ChickenActions.xml" TagDef="Animations/Mannequin/ADB/ChickenTags.xml">
 <FragmentList>
  <Idle>
   <Fragment BlendOutDuration="0.2" Tags="">
    <AnimLayer>
     <Blend ExitTime="0" StartTime="0" Duration="0.1"/>
     <Animation name="anim_chicken_idle" flags="Loop"/>
    </AnimLayer>
   </Fragment>
  </Idle>
  <Nav>
   <Fragment BlendOutDuration="0.2" Tags="Foraging">
    <AnimLayer>
     <Blend ExitTime="0" StartTime="0" Duration="0.2"/>
     <Animation name="anim_chicken_walk_forage" flags="Loop" speed="2"/>
    </AnimLayer>
   </Fragment>
   <Fragment BlendOutDuration="0.2" Tags="">
    <AnimLayer>
     <Blend ExitTime="0" StartTime="0" Duration="0.2"/>
     <Animation name="anim_chicken_walk" flags="Loop" speed="2"/>
    </AnimLayer>
   </Fragment>
  </Nav>
  <Jump>
   <Fragment BlendOutDuration="0.2" Tags="">
    <AnimLayer>
     <Blend ExitTime="0" StartTime="0.30000001" Duration="0.2"/>
     <Animation name="anim_chicken_flapping"/>
     <Blend ExitTime="0.5" StartTime="0" Duration="0.2"/>
     <Animation name=""/>
    </AnimLayer>
   </Fragment>
  </Jump>
  <Fidget>
   <Fragment BlendOutDuration="0.2" Tags="">
    <AnimLayer>
     <Blend ExitTime="0" StartTime="0" Duration="0.2"/>
     <Animation name="anim_chicken_scared"/>
    </AnimLayer>
   </Fragment>
  </Fidget>
 </FragmentList>
 <FragmentBlendList>
  <Blend from="Nav" to="Nav">
   <Variant from="" to="Foraging">
    <Fragment BlendOutDuration="0.2" selectTime="0" enterTime="0"/>
   </Variant>
   <Variant from="Foraging" to="">
    <Fragment BlendOutDuration="0.2" selectTime="0" enterTime="0"/>
   </Variant>
  </Blend>
 </FragmentBlendList>
</AnimDB>
