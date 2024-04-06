<?php

namespace App\Entity\Raw;

use Gedmo\Timestampable\Traits\TimestampableEntity;

abstract class BaseEntity extends AbstractEntity
{
    use TimestampableEntity;
}