<?php
namespace App\Dto;

use JMS\Serializer\Annotation as Serialization;
use JMS\Serializer\Serializer;
use Symfony\Component\Validator\Constraint;

interface DtoInterface
{
    #[Serialization\Exclude]
    public function setSerializer(Serializer $serializer): void;

    #[Serialization\Exclude]
    public function getSerializer(): Serializer;

    #[Serialization\Exclude]
    public function toArray(): array;

    #[Serialization\Exclude]
    public function toJson(): string;

    /** @return Constraint[] */
    #[Serialization\Exclude]
    public static function getParamsConstraints(): array;
}