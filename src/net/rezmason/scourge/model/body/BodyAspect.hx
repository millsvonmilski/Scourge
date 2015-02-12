package net.rezmason.scourge.model.body;

import net.rezmason.praxis.aspect.Aspect;

class BodyAspect extends Aspect {
    @aspect(null) var HEAD;
    @aspect(null) var BODY_FIRST;
    @aspect(null) var BODY_NEXT;
    @aspect(null) var BODY_PREV;

    @aspect(0) var TOTAL_AREA;

    @aspect(null) var CAVITY_FIRST;
    @aspect(null) var CAVITY_NEXT;
    @aspect(null) var CAVITY_PREV;
}
