<?php

namespace App\Dto;

use JMS\Serializer\Annotation as Serialization;
use JMS\Serializer\Serializer;

abstract class AbstractDto implements DtoInterface
{
    #[Serialization\Exclude]
    protected Serializer $serializer;

    #[Serialization\Exclude]
    public function setSerializer(Serializer $serializer): void
    {
        $this->serializer = $serializer;
    }

    #[Serialization\Exclude]
    public function getSerializer(): Serializer
    {
        return $this->serializer;
    }

    #[Serialization\Exclude]
    public function toArray(): array
    {
        return $this->getSerializer()->toArray($this);
    }

    #[Serialization\Exclude]
    public function toJson(): string
    {
        return $this->getSerializer()->serialize($this, 'json');
    }

    #[Serialization\Exclude]
    public static function getParamsConstraints(): array
    {
        return [];
    }
}